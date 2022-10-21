" Bulk editing thing


function! BetterMacro()
  " always use register w (@w)
  unmap q
  let g:undo_save_point = changenr()
  normal qw^
  nnoremap q <noop>
endfunction

" nnoremap Q :call BetterMacro()<CR>
nnoremap Q q

xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction

nnoremap <leader>U :undo


"Insert semicolons and commas
let @s="mtA;kj`t"
let @c="mtA,kj`t"
noremap <leader>; @s
noremap <leader>, @c
vnoremap <leader>; :normal @s<CR>
vnoremap <leader>, :normal @c<CR>

if has('nvim')
  set inccommand=split
endif
