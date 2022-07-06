if get(g:, 'zprint#make_autocmd')
    augroup zprint
      autocmd! BufWritePre <buffer> call zprint#apply()
    augroup END
endif

command! -buffer Zprint call zprint#apply()
