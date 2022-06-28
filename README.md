# zprint.vim

A Vim plugin that runs [`zprint`][zprint] when you save.

Most of the code is based off [vim-go][].

[zprint]: https://github.com/kkinnear/zprint
[vim-go]: https://github.com/fatih/vim-go

## Install

You must install `zprint` first.

If you use [Homebrew](https://brew.sh/), you can do it with `brew install bfontaine/utils/zprint`.

### Pathogen

    git clone https://github.com/bfontaine/zprint.vim ~/.vim/bundle/zprint.vim

### VimPlug

    Plug 'bfontaine/zprint.vim'

### Vundle

    Plugin 'bfontaine/zprint.vim'

### Manual installation

Clone this repository, then copy the files from `autoload` and `ftplugin` in the same directories
under `~/.vim`.

### Configuration

The variable `g:zprint#options_map` will be passed to the `zprint` call as its options map.

```vim
" use the project-specific .zprintrc instead of the global one, if available
let g:zprint#options_map = '{:search-config? true}'
```

