vim9script

#    Copyright (C) 2022  Elliot<hack00mind@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

const GIT_LENS_DEFAULT_CONFIG = {
    blame_prefix: '    ',
    blame_highlight: 'Comment',
    blame_wrap: true,
    blame_empty_line: true,
    blame_delay: 500,
}

export def Initialize()
    if empty(prop_type_get('git-lens-blame'))
        prop_type_add('git-lens-blame', { highlight: GetConfig('blame_highlight'), })
    endif
    augroup git-lens
        autocmd!
        autocmd BufEnter * OnBufferEnter()
        autocmd BufLeave * OnBufferLeave()
        autocmd BufWritePost,CursorMoved * Refresh()
    augroup END
    EnableShow()
enddef

export def Deinitialize()
    augroup git-lens
        autocmd!
    augroup END
    DisableShow()
enddef

def OnBufferEnter()
    if !g:GIT_LENS_ENABLED
        return
    endif
    const is_buffer_tracked = IsBufferTracker()
    if !is_buffer_tracked
        b:git_lens_enabled = false
        return
    endif
    b:git_lens_enabled = true
    UpdateGitUserConfig()
    Refresh()
enddef

def OnBufferLeave()
    if !g:GIT_LENS_ENABLED || !get(b:, 'git_lens_enabled', false)
        return
    endif
    b:git_lens_previous_line = 0
    DisableShow()
enddef

def EnableShow()
    if !g:GIT_LENS_ENABLED || !get(b:, 'git_lens_enabled', false)
        return
    endif

    Show()
enddef

var git_lens_timer_id = -1
def DisableShow()
    if git_lens_timer_id != -1
        timer_stop(git_lens_timer_id)
    endif
    git_lens_timer_id = -1
    ClearVirtualText()
enddef

export def Refresh()
    if !g:GIT_LENS_ENABLED || !get(b:, 'git_lens_enabled', false)
        return
    endif

    const current_line = line('.')
    if get(b:, 'git_lens_previous_line', 0) != current_line
        b:git_lens_previous_line = current_line
    else
        return
    endif

    if git_lens_timer_id != -1
        timer_stop(git_lens_timer_id)
    endif

    ClearVirtualText()
    git_lens_timer_id = timer_start(GetConfig('blame_delay'), (id) => Show())
enddef

def IsBufferTracker(): bool
    const file_path = shellescape(UnixPath(expand('%:p')))
    if empty(file_path)
        return false
    endif

    const dir_path = shellescape(UnixPath(expand('%:h')))
    const result = system('git -C ' .. dir_path .. ' ls-files --error-unmatch ' .. file_path)
    if result[0 : 4] ==# 'fatal'
        return false
    endif

    return true
enddef

var blame_current_user_email = 'unknown'
def UpdateGitUserConfig()
    const current_dir_path = shellescape(UnixPath(expand('%:h')))
    blame_current_user_email = '<' .. trim(system('git -C ' .. current_dir_path .. ' config --get user.email')) .. '>'
enddef

def UnixPath(path: string): string
    return IS_WINDOWS ? substitute(path, '\\', '/', 'g') : path
enddef
const IS_WINDOWS = has('win16') || has('win32') || has('win64') || has('win95')

var blame_job = null_job

def Show()
    const is_special_buffer = &buftype !=# ''
    if is_special_buffer
        return
    endif

    if !GetConfig('blame_empty_line') && empty(getline('.'))
        return
    endif

    if !GetConfig('blame_wrap') && (winwidth(0) - &numberwidth - 1) == virtcol('$')
        return
    endif

    const file_path = UnixPath(expand('%:p'))
    if empty(file_path)
        return
    endif
    const dir_path = UnixPath(expand('%:p:h'))
    const line_num = line('.')

    const blame_command = [
        'git',
        '-C',
        dir_path,
        '--no-pager',
        'blame',
        '--line-porcelain',
        '-L',
        line_num .. ',' .. line_num,
        '--',
        file_path
    ]

    if job_status(blame_job) == "run"
        job_stop(blame_job)
    endif
    blame_job = job_start(blame_command, {
        "out_cb": (channel, message) => ShowBlameWithVirtualText(message),
        "mode": "raw"
    })
enddef

def ShowBlameWithVirtualText(message: string)

    const lines = split(message, '\n')

    const hash = split(lines[0], ' ')[0]
    const hash_is_empty = empty(matchstr(hash, '\c[0-9a-f]\{40}'))

    if hash_is_empty
        echoerr 'hash is empty' .. hash
        if message =~? 'fatal' && message =~? 'not a git repository'
            echoerr '[git-lens] Not a git repository'
            return
        endif

        # Known git errors will be silenced
        if message =~? 'no matches found'
            return
        elseif message =~? 'no such path'
            return
        elseif message =~? 'is outside repository'
            return
        elseif message =~? 'has only' && message =~? 'lines'
            return
        elseif message =~? 'no such ref'
            return
        endif

        # Echo unknown errors in order to catch them
        echoerr '[git-lens] ' .. message
        return
    endif

    final commit_data = {}
    for row in lines[0 : ]
        const row_words = split(row, ' ')
        const property = row_words[0]
        var value = strpart(row, len(property) + 1)
        if property =~? 'time'
            value = GetRelativeTime(value)
        endif
        commit_data[property] = value
    endfor
    if get(commit_data, 'author-mail', '') ==? blame_current_user_email
        commit_data.author = 'You'
    endif
    if get(commit_data, 'author', '') ==? 'Not Committed Yet'
        commit_data.author = 'You'
        commit_data.summary = 'Uncommitted changes'
    endif

    const result = FormatBlameText(commit_data)

    ClearVirtualText()
    SetVirtualText(result)
enddef

def SetVirtualText(message: string)
    const text_wrap = GetConfig('blame_wrap') ? 'wrap' : 'truncate'
    const line_num = line('.')

    prop_add(
        line_num,
        0,
        {
            type: 'git-lens-blame',
            text: message, text_align: 'after',
            text_wrap: text_wrap,
        }
    )
enddef

def ClearVirtualText()
    prop_remove({ type: 'git-lens-blame' })
enddef

def GetRelativeTime(commit_timestamp: string): string
    const current_timestamp = localtime()
    const elapsed = current_timestamp - str2nr(commit_timestamp)

    # We have no info how long ago line saved
    if elapsed == 0
        return 'a while ago'
    endif

    const minute_seconds = 60
    const hour_seconds = minute_seconds * 60
    const day_seconds = hour_seconds * 24
    const month_seconds = day_seconds * 30
    const year_seconds = month_seconds * 12

    if elapsed < minute_seconds
        return SecondsToRelativeString(elapsed, 1, 'second')
    elseif elapsed < hour_seconds
        return SecondsToRelativeString(elapsed, 60, 'minute')
    elseif elapsed < day_seconds
        return SecondsToRelativeString(elapsed, hour_seconds, 'hour')
    elseif elapsed < month_seconds
        return SecondsToRelativeString(elapsed, day_seconds, 'day')
    elseif elapsed < year_seconds
        return SecondsToRelativeString(elapsed, month_seconds, 'month')
    else
        return SecondsToRelativeString(elapsed, year_seconds, 'year')
    endif
enddef

def SecondsToRelativeString(seconds: number, divisor: number, unit: string): string
    const amount = float2nr(round(seconds / divisor))
    const countable_unit = amount > 1 ? unit .. 's' : unit
    return string(amount) .. ' ' .. countable_unit .. ' ago'
enddef

def GetConfig(key: string): any
    if !exists('g:GIT_LENS_CONFIG.' .. key)
        return GIT_LENS_DEFAULT_CONFIG[key]
    endif

    return g:GIT_LENS_CONFIG[key]
enddef

def FormatBlameText(commit_data: any): string
    if exists('g:GIT_LENS_CONFIG.blame_template')
        var result = g:GIT_LENS_CONFIG.blame_template
        for field in ['author', 'author-time', 'summary']
            result = substitute(result, '\m\C<' .. field .. '>', commit_data[field], 'g')
        endfor
        return result
    else
        return GetConfig('blame_prefix')
            .. commit_data['author']
            .. ' • '
            .. commit_data['author-time']
            .. ' • '
            .. commit_data['summary']
    endif
enddef
