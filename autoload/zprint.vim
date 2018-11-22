" Based off https://github.com/fatih/vim-go/tree/6866d086ff3492060832a204feb5b8a3dd2777e5
" Copyright (c) 2015, Fatih Arslan
" License file: https://github.com/fatih/vim-go/blob/0ff2a642c4353da6316fac42f2cc2ce2f536ef9f/LICENSE

let s:cpo_save = &cpo
set cpo&vim

function zprint#apply()
  let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')
  " Save cursor position and many other things.
  let l:curw = winsaveview()

  " Write current unsaved buffer to a temp file
  let l:tmpname1 = tempname() . '.zprint1'
  let l:tmpname2 = tempname() . '.zprint2'
  call writefile(zprint#GetLines(), l:tmpname1)

  let current_col = col('.')

  let l:cmd = 'zprint < ' . l:tmpname1 . ' > ' . l:tmpname2
  let l:out = zprint#System(l:cmd)

  let diff_offset = len(readfile(l:tmpname2)) - line('$')

  call zprint#update_file(l:tmpname2, fname)

  " clean up
  call delete(l:tmpname1)
  call delete(l:tmpname2)

  " Restore our cursor/windows positions.
  call winrestview(l:curw)

  " be smart and jump to the line the new statement was added/removed
  call cursor(line('.') + diff_offset, current_col)

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

  if executable('/bin/sh')
      set shell=/bin/sh shellredir=>%s\ 2>&1 shellcmdflag=-c
  endif

  try
    return call('system', [a:cmd] + a:000)
  finally
    " Restore original values
    let &shell = l:shell
    let &shellredir = l:shellredir
    let &shellcmdflag = l:shellcmdflag
  endtry
endfunction

" System runs a shell command "str". Every arguments after "str" is passed to
" stdin.
function! zprint#System(str, ...) abort
  return call('s:system', [a:str] + a:000)
endfunction

function! s:exec(cmd, ...) abort
  let l:bin = a:cmd[0]
  let l:cmd = join([l:bin] + a:cmd[1:])
  let l:out = call('s:system', [l:cmd] + a:000)
  return [l:out, v:shell_error]
endfunction

" Get all lines in the buffer as a a list.
function! zprint#GetLines()
  let buf = getline(1, '$')
  if &encoding != 'utf-8'
    let buf = map(buf, 'iconv(v:val, &encoding, "utf-8")')
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
