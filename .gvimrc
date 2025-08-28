" MacVim-specific GUI settings
set guifont=Monolisa:h16

" Window size
set lines=40
set columns=120

" GUI options
set guioptions-=T  " Remove toolbar
set guioptions-=r  " Remove right scrollbar
set guioptions-=L  " Remove left scrollbar

" Enable ligatures if your font supports them
if has("gui_macvim")
  set macligatures
endif

" Smooth scrolling
set linespace=2

" Native tabs in MacVim
set guioptions+=e

" Enable mouse
set mouse=a