## git-lens.vim

A vim9 plugin inspired by VSCode's GitLens. 

## Installation

### Vim8 native pack system

Clone all file to your runtime's `pack/**/start` directory, like:

`git clone git@github.com:Eliot00/git-lens.vim.git ~/.vim/pack/plugins/start`

### vim-plug

1. Add the following line to your `~/.vimrc`:

```
call plug#begin()
...
Plug 'Eliot00/git-lens.vim'
...
call plug#end()
```

2. Run `:PlugInstall`.

## Configuration

`git-lens.vim` is default not enabled, you can use `:call ToggleGitLens()` to toggle this plugin. And if you want this plugin default enabled, just set the global variable `GIT_LENS_ENABLED` to `true`.

## Appreciation

This project is strongly inspired by [GitLens](https://github.com/gitkraken/vscode-gitlens) and [blamer.nvim](https://github.com/APZelos/blamer.nvim).
