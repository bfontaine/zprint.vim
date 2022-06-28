" Based off https://github.com/fatih/vim-go/tree/6866d086ff3492060832a204feb5b8a3dd2777e5
" Copyright (c) 2015, Fatih Arslan
" License file: https://github.com/fatih/vim-go/blob/0ff2a642c4353da6316fac42f2cc2ce2f536ef9f/LICENSE

let s:cpo_save = &cpo
set cpo&vim

function zprint#apply()
  let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')
  " Save cursor position and many other things.
  let l:curw = winsaveview()

  let l:current_lines = zprint#GetLines()

  " Write current unsaved buffer to a temp file
  let l:inputfile = tempname() . '.zprint'
  call writefile(l:current_lines, l:inputfile)

  if has('win32')
    let l:inputfile = tr(l:inputfile, '\', '/')
  endif

  let current_col = col('.')
  let l:options_map = get(g:, 'zprint#options_map', '{}')
  let l:cmd = 'zprint "' . l:options_map . '" < ' . l:inputfile
  let l:out = zprint#System(l:cmd)
  let l:updated_lines = split(l:out, "\n")

  call delete(l:inputfile)

  " Only write to file on formatting change
  " https://github.com/bfontaine/zprint.vim/issues/1
  if l:current_lines != l:updated_lines
    let diff_offset = len(l:updated_lines) - line('$')

    let l:outputfile = tempname() . '.zprint'
    call writefile(l:updated_lines, l:outputfile)
    call zprint#update_file(l:outputfile, fname)
    call delete(l:outputfile)

    " be smart and jump to the line the new statement was added/removed
    call cursor(line('.') + diff_offset, current_col)
  end

  " Restore our cursor/windows positions.
  call winrestview(l:curw)

  " Syntax highlighting breaks less often.
  syntax sync fromstart
endfunction

let s:env_cache = {}

" Run a shell command.
"
" It will temporary set the shell to /bin/sh for Unix-like systems if possible,
" so that we always use a standard POSIX-compatible Bourne shell (and not e.g.
" csh, fish, etc.) See #988 and #1276.
function! s:system(cmd, ...) abort
  " Preserve original shell, shellredir and shellcmdflag values
  let l:shell = &shell
  let l:shellredir = &shellredir
  let l:shellcmdflag = &shellcmdflag
  let l:shellquote = &shellquote
  let l:shellxquote = &shellxquote

  if !has('win32')
    if executable('/bin/sh')
      set shell=/bin/sh shellredir=>%s\ 2>&1 shellcmdflag=-c
    endif
  else
    if executable($COMSPEC)
      let &shell = $COMSPEC
      set shellcmdflag=/C
      set shellquote&
      set shellxquote&
    endif
  endif

  try
    return call('system', [a:cmd] + a:000)
  finally
    " Restore original values
    let &shell = l:shell
    let &shellredir = l:shellredir
    let &shellcmdflag = l:shellcmdflag
    let &shellquote = l:shellquote
    let &shellxquote = l:shellxquote
  endtry
endfunction

" System runs a shell command "str". Every arguments after "str" is passed to
" stdin.
function! zprint#System(str, ...) abort
  return call('s:system', [a:str] + a:000)
endfunction

" Get all lines in the buffer as a a list.
function! zprint#GetLines()
  let buf = getline(1, '$')
  if &encoding != 'utf-8'
    let buf = map(buf, 'iconv(v:val, &encoding, "utf-8")')
  endif
  if &l:fileformat == 'dos'
    " line2byte() depend on 'fileformat' option.
    " so if fileformat is 'dos', 'buf' must include '\r'.
    let buf = map(buf, 'v:val."\r"')
  endif
  return buf
endfunction

" update_file updates the target file with the given formatted source
function! zprint#update_file(source, target)
  " remove undo point caused via BufWritePre
  try | silent undojoin | catch | endtry

  let old_fileformat = &fileformat
  if exists("*getfperm")
    " save file permissions
    let original_fperm = getfperm(a:target)
  endif

  call rename(a:source, a:target)

  " restore file permissions
  if exists("*setfperm") && original_fperm != ''
    call setfperm(a:target , original_fperm)
  endif

  " reload buffer to reflect latest changes
  silent edit!

  let &fileformat = old_fileformat
  let &syntax = &syntax

  let l:listtype = 'locationlist'

  " the title information was introduced with 7.4-2200
  " https://github.com/vim/vim/commit/d823fa910cca43fec3c31c030ee908a14c272640
  if has('patch-7.4.2200')
    " clean up previous list
    let l:list_title = getloclist(0, {'title': 1})
  else
    " can't check the title, so assume that the list was for zprint.
    let l:list_title = {'title': 'Format'}
  endif

  if has_key(l:list_title, "title") && l:list_title['title'] == "Format"
    " https://github.com/fatih/vim-go/blob/0ff2a642c4353da6316fac42f2cc2ce2f536ef9f/autoload/go/list.vim#L102
    lex []
  endif
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et
