" Nord
let g:nord_uniform_diff_background = 1
let g:nord_italic = 1

" hashivim/vim-terraform
let g:terraform_fmt_on_save=1

" mergetool
let g:mergetool_layout = 'mr'
let g:mergetool_prefer_revision = 'local'

call plug#begin('~/.vim/plugged')
" Defaults everyone can agree on
Plug 'tpope/vim-sensible'
" dark theme
Plug 'arcticicestudio/nord-vim'
" light theme
" Plug 'sonph/onehalf', {'rtp': 'vim/'}
" Git
Plug 'tpope/vim-fugitive'
" GitHub extension for fugitive.vim
Plug 'tpope/vim-rhubarb'
" git mergetool
Plug 'samoshkin/vim-mergetool'
" Change case
Plug 'tpope/vim-abolish'
" Modify file explorer
" Plug 'tpope/vim-vinegar'
" handy shortcuts
Plug 'tpope/vim-unimpaired'
" JS/TS
Plug 'pangloss/vim-javascript'
" Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'hashivim/vim-terraform'
Plug 'tpope/vim-markdown'
Plug 'towolf/vim-helm'
" Kotlin
Plug 'udalov/kotlin-vim'
" TOML
Plug 'cespare/vim-toml'
" Plug 'stephpy/vim-yaml'

" vi filename:42
Plug 'wsdjeg/vim-fetch'

if has('nvim')
" Find files
Plug 'nvim-lua/plenary.nvim'
" z navigation
" Plug 'PsychoLlama/teleport.vim'
" Plug 'nvim-telescope/telescope.nvim'

" Go
Plug 'fatih/vim-go'
" lsp and completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Markdown
Plug 'iamcco/markdown-preview.nvim', {'do': 'cd app && yarn install'}
endif
call plug#end()

" set grepprg=rg\ --vimgrep\ --no-config\ --hidden\ --ignore-case\ --glob='!node_modules/*'\ --glob='!**/*.git/*'\ --glob='!**/*dist/*'\ --glob='!**/*vendor/*'\ --max-columns=210
set grepprg=rg\ --vimgrep\ --max-columns=210

" theme
colorscheme nord
" colorscheme onehalflight

" use system clipboard
" set clipboard=unnamed
set clipboard+=unnamedplus

" Show next match and center screen
nnoremap n nzz
nnoremap N Nzz

" find tab completion for files
set path+=**

" jump between keyword pairs with percent command
" runtime macros/matchit.vim

autocmd BufNewFile,BufRead *.hcl set syntax=terraform
autocmd BufRead,BufNewFile *.gotmpl set ft=helm
autocmd BufNewFile,BufRead *.jsx set syntax=javascriptreact

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
" set nohlsearch

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


if has('nvim')
" python
autocmd FileType python let b:coc_root_patterns = ['.git', '.env', 'venv', '.venv', 'setup.cfg', 'setup.py', 'pyproject.toml', 'pyrightconfig.json']

" vim-go
let g:go_fmt_command = "goimports"

" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0

" COC
" https://github.com/neoclide/coc.nvim
"
" TextEdit might fail if hidden is not set.
set hidden

" Some servers have issues with backup files, see #649.
set nobackup
set nowritebackup

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

function! Help()
  if &filetype == 'git'
    execute '!' . &keywordprg . " " . expand('<cword>')
    return
  endif
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Use K to show documentation in preview window.
 " nnoremap <silent> K :call <SID>Help()<CR>
nnoremap <silent> K :call Help()<CR>

command! -nargs=0 Help :call Help()

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> for scroll float windows/popups.
" Note coc#float#scroll works on neovim >= 0.4.0 or vim >= 8.2.0750
nnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"

" NeoVim-only mapping for visual mode scroll
" Useful on signatureHelp after jump placeholder of snippet expansion
if has('nvim')
  vnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#nvim_scroll(1, 1) : "\<C-f>"
  vnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#nvim_scroll(0, 1) : "\<C-b>"
endif

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support.
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics.
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
endif
