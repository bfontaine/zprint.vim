augroup zprint
  autocmd! BufWritePre <buffer> call zprint#apply()
augroup END

command! -buffer Zprint call zprint#apply()
