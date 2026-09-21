" Basic Settings
set nocompatible
filetype plugin indent on
syntax on

" Nord Theme Settings
let g:nord_uniform_diff_background = 1
let g:nord_enable_italic = 1

" Vim-Plug Setup
call plug#begin('~/.vim/plugged')
" Defaults everyone can agree on
Plug 'tpope/vim-sensible'
Plug 'nordtheme/vim'

" Essential plugins for both Vim and MacVim
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'editorconfig/editorconfig-vim'
Plug 'wsdjeg/vim-fetch'  " vi filename:42

" Neovim-specific plugins
if has('nvim')
  " LSP and completion
  Plug 'nvim-lua/plenary.nvim'
  Plug 'neovim/nvim-lspconfig'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'L3MON4D3/LuaSnip', {'on': []}
  Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v3.x'}
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
  Plug 'hrsh7th/cmp-path'
  Plug 'lukas-reineke/cmp-rg'
  
  " AI - Claude via Copilot (loaded asynchronously after UI paint; see init.lua)
  Plug 'zbirenbaum/copilot.lua', {'on': []}
  Plug 'zbirenbaum/copilot-cmp', {'on': []}
  Plug 'nvim-lua/plenary.nvim'
  Plug 'CopilotC-Nvim/CopilotChat.nvim', {'on': []}

  " Visual enhancements (loaded asynchronously; pulls in treesitter)
  Plug 'lukas-reineke/indent-blankline.nvim', {'on': []}
  
  " Language-specific
  Plug 'fatih/vim-go'
  Plug 'pangloss/vim-javascript'
  Plug 'leafgarland/typescript-vim'
  Plug 'hashivim/vim-terraform'
  Plug 'tpope/vim-markdown'
  Plug 'towolf/vim-helm'
  Plug 'samoshkin/vim-mergetool'

  " Markdown preview: in-buffer rendering + browser live preview
  Plug 'MeanderingProgrammer/render-markdown.nvim'
  Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': 'markdown' }
endif
call plug#end()

" Color Scheme
if !has('gui_running') && &term =~ '\%(screen\|tmux\)'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set termguicolors
colorscheme nord

" General Settings
set number
set expandtab
set smarttab
set shiftwidth=2
set tabstop=2
set autowrite
set noswapfile
set hlsearch
set incsearch
set ignorecase
set path+=**

" Clipboard
if has('nvim')
  set clipboard+=unnamedplus
else
  set clipboard=unnamed
endif

" Key Mappings
nnoremap d "_d
nnoremap x "_x
nnoremap n nzz
nnoremap N Nzz

" File Explorer
let g:netrw_banner = 0
let g:netrw_keepdir = 0
let g:netrw_list_hide = '\.\.\/,\.\/'

fu! OpenExplorer()
    try
        silent :Rex
    catch
        :Ex
    endtry
endfu
nmap <silent> - :call OpenExplorer()<cr>

" Auto Commands
autocmd BufWritePre * %s/\s\+$//e
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif

" File Type Associations
autocmd BufNewFile,BufRead *.hcl set syntax=terraform
autocmd BufRead,BufNewFile *.gotmpl set ft=helm
autocmd BufNewFile,BufRead *.jsx set syntax=javascriptreact

" Grep Settings
set grepprg=rg\ --vimgrep\ --max-columns=210

" Neovim-specific Settings
if has('nvim')
  " Terraform
  let g:terraform_fmt_on_save=1
  let g:terraform_binary_path="tofu"
  
  " Mergetool
  let g:mergetool_layout = 'mr'
  let g:mergetool_prefer_revision = 'local'
  
  " Go
  let g:go_fmt_command = "goimports"
  let g:go_def_mapping_enabled = 0
endif
" Speak Selection
" Terminal-side stand-in for the macOS Option+Esc hotkey, which reads nothing
" inside WezTerm (no accessibility text is exposed). Uses the same
" ~/.local/bin/speak script as the tmux and WezTerm bindings.
" Visual  <leader>s : speak the selection      Normal <leader>s : stop speaking
" Selecting in Vim rather than with the mouse avoids dragging in line numbers.
if has('mac') || has('macunix')
  function! s:Speak(text) abort
    if a:text =~# '^\_s*$'
      silent call system('pkill -x say')
      return
    endif
    let l:file = tempname()
    call writefile(split(a:text, "\n", 1), l:file)
    " speak reads the file fully before backgrounding say, so rm is safe here.
    silent call system(printf('(~/.local/bin/speak %s; rm -f %s) >/dev/null 2>&1 &',
          \ shellescape(l:file), shellescape(l:file)))
  endfunction

  " Yank through register z explicitly: clipboard=unnamed[plus] means the
  " unnamed register is the system clipboard, and this must not clobber it.
  function! s:SpeakSelection() abort
    let l:save = getreg('z')
    let l:type = getregtype('z')
    silent normal! gv"zy
    call s:Speak(@z)
    call setreg('z', l:save, l:type)
  endfunction

  xnoremap <silent> <leader>s :<C-u>call <SID>SpeakSelection()<CR>
  nnoremap <silent> <leader>s :call <SID>Speak('')<CR>
endif
