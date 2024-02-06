## git-lens.vim

A vim9 plugin inspired by VSCode's GitLens. 

This plugin is written using vim9 script, **make sure the output is 1 with the `:echo has('vim9script')` command in vim.**

![preview](https://user-images.githubusercontent.com/18375468/185842698-f84c7c55-fdbe-4573-817c-e19934c0e436.gif)

## Installation

### Vim8 native pack system

Clone all file to your runtime's `pack/**/start` directory, like:

`git clone git@github.com:Eliot00/git-lens.vim.git ~/.vim/pack/plugins/start`

### vim-plug

1. Add the following line to your `~/.vimrc`:

```vim
call plug#begin()
...
Plug 'Eliot00/git-lens.vim'
...
call plug#end()
```

2. Run `:PlugInstall`.

## Configuration

This plugin is default not enabled, you can use `:call ToggleGitLens()` to toggle this plugin. And if you want this plugin default enabled, just set the global variable `g:GIT_LENS_ENABLED` to `true`.

### GIT_LENS_CONFIG

Here is a global dict `g:GIT_LENS_CONFIG` for customization:

```vim
g:GIT_LENS_CONFIG = {
    blame_prefix: '----', # default is four spaces
    blame_highlight: 'YourHighlight', # Comment
    blame_wrap: false, # blame text wrap
    blame_empty_line: false, # Whether to blame empty line.
    blame_delay: 200, # default is 500
}
```

## Appreciation

This project is strongly inspired by [GitLens](https://github.com/gitkraken/vscode-gitlens) and [blamer.nvim](https://github.com/APZelos/blamer.nvim).
