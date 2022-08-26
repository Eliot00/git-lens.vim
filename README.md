## git-lens.vim

A vim9 plugin inspired by VSCode's GitLens. 

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

This plugin is default not enabled, you can use `:call ToggleGitLens()` to toggle this plugin. And if you want this plugin default enabled, just set the global variable `GIT_LENS_ENABLED` to `true`.

### GIT_LENS_CONFIG

Here is a global dict `GIT_LENS_CONFIG` for customization:

```vim
g:GIT_LENS_CONFIG = {
    blame_prefix: '----', # default is four spaces
    blame_delay: 2000, # 500
    blame_highlight: 'YourHighlight', # Comment
}
```

## Appreciation

This project is strongly inspired by [GitLens](https://github.com/gitkraken/vscode-gitlens) and [blamer.nvim](https://github.com/APZelos/blamer.nvim).
