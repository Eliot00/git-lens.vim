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

import autoload 'git_lens/blame.vim' as blame

if exists('LOADED_GIT_LENS') || &cp
    finish
endif
g:LOADED_GIT_LENS = true

if !has('textprop')
    echoerr '[git-lens] needs textprop feature'
    finish
endif

def g:ToggleGitLens()
    const is_special_buffer = &buftype !=# ''
    if is_special_buffer
        echoerr '[git-lens] This is a special buffer'
        return
    endif

    if !get(g:, 'GIT_LENS_ENABLED', false) || !get(b:, 'git_lens_enabled', false)
        g:GIT_LENS_ENABLED = true
        b:git_lens_enabled = true
        blame.Initialize()
    else
        g:GIT_LENS_ENABLED = false
        b:git_lens_enabled = false
        blame.Deinitialize()
    endif
enddef

if get(g:, 'GIT_LENS_ENABLED', false)
    blame.Initialize()
endif
