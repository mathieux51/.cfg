if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Nord
let g:nord_uniform_diff_background = 1
let g:nord_italic = 1

" hashivim/vim-terraform
let g:terraform_fmt_on_save=1

" mergetool
let g:mergetool_layout = 'mr'
let g:mergetool_prefer_revision = 'local'

call plug#begin('~/.vim/plugged')
" dark theme
Plug 'arcticicestudio/nord-vim'
" light theme
Plug 'sonph/onehalf', {'rtp': 'vim/'}
" lsp and completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Git
Plug 'tpope/vim-fugitive'
" GitHub extension for fugitive.vim
Plug 'tpope/vim-rhubarb'
" git mergetool
Plug 'samoshkin/vim-mergetool'

" Change case
Plug 'tpope/vim-abolish'
" Modify file explorer
Plug 'tpope/vim-vinegar'
" Defaults everyone can agree on
Plug 'tpope/vim-sensible'
" handy shortcuts
Plug 'tpope/vim-unimpaired'
" JS/TS
Plug 'pangloss/vim-javascript'
" Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
Plug 'Glench/Vim-Jinja2-Syntax'
" Plug 'mrk21/yaml-vim'
Plug 'hashivim/vim-terraform'
Plug 'tpope/vim-markdown'
Plug 'fatih/vim-go'
Plug 'towolf/vim-helm'
" Kotlin
Plug 'udalov/kotlin-vim'
Plug 'cespare/vim-toml'
call plug#end()

set grepprg=rg\ --vimgrep\ --no-config\ --hidden\ --ignore-case\ --glob='!node_modules/*'\ --glob='!**/*.git/*'\ --glob='!**/*dist/*'\ --glob='!**/*vendor/*'\ --max-columns=210

" theme
colorscheme nord
" colorscheme onehalflight

" use system clipboard
set clipboard=unnamed

" Show next match and center screen
nnoremap n nzz
nnoremap N Nzz

" find tab completion for files
set path+=**

" jump between keyword pairs with percent command
" runtime macros/matchit.vim
autocmd BufNewFile,BufRead *.hcl set syntax=terraform
" autocmd BufWritePre *.tf !terraform fmt -recursive

autocmd BufNewFile,BufRead *.gotmpl set syntax=yaml

autocmd BufNewFile,BufRead *.jsx set syntax=javascriptreact

" python
autocmd FileType python let b:coc_root_patterns = ['.git', '.env', 'venv', '.venv', 'setup.cfg', 'setup.py', 'pyproject.toml', 'pyrightconfig.json']

" vim-go
let g:go_fmt_command = "goimports"

" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0

" https://github.com/fatih/vim-go-tutorial#fix-it
set autowrite

" https://vim.fandom.com/wiki/Remove_unwanted_spaces#Automatically_removing_all_trailing_whitespace
autocmd BufWritePre * %s/\s\+$//e

set noswapfile

" Use spaces instead of tabs
set expandtab
" Be smart when using tabs ;)
set smarttab
" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2

" see line numbers
set number

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

set ignorecase

" Enable filetype plugins
filetype plugin on
filetype indent on


" help last-position-jump
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif

" COC
source ~/.vim/coc.vim
