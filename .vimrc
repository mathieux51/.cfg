" hashivim/vim-terraform
let g:terraform_fmt_on_save=1
let g:terraform_binary_path="tofu"

" mergetool
let g:mergetool_layout = 'mr'
let g:mergetool_prefer_revision = 'local'

" Nord
let g:nord_uniform_diff_background = 1
let g:nord_italic = 1

call plug#begin('~/.vim/plugged')
" Defaults everyone can agree on
Plug 'tpope/vim-sensible'
Plug 'nordtheme/vim'
" Plug 'vim-airline/vim-airline'

" Git
Plug 'tpope/vim-fugitive'
" GitHub extension for fugitive.vim
Plug 'tpope/vim-rhubarb'
" Plug 'shumphrey/fugitive-gitlab.vim'

Plug 'editorconfig/editorconfig-vim'

" git mergetool
Plug 'samoshkin/vim-mergetool'
" Change case
" Plug 'tpope/vim-abolish'
" Modify file explorer
" Plug 'tpope/vim-vinegar'
" handy shortcuts
" Plug 'tpope/vim-unimpaired'
" JS/TS
Plug 'pangloss/vim-javascript'
" Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
" Plug 'Glench/Vim-Jinja2-Syntax'
Plug 'hashivim/vim-terraform'
Plug 'tpope/vim-markdown'
Plug 'towolf/vim-helm'
" Kotlin
" Plug 'udalov/kotlin-vim'
" TOML
" Plug 'cespare/vim-toml'
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
"  Uncomment the two plugins below if you want to manage the language servers from neovim
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'L3MON4D3/LuaSnip'
Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v3.x'}

Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
Plug 'hrsh7th/cmp-path'
Plug 'lukas-reineke/cmp-rg'

Plug 'zbirenbaum/copilot.lua'
Plug 'zbirenbaum/copilot-cmp'
" Plug 'williamboman/mason.nvim'
" Plug 'williamboman/mason-lspconfig.nvim'


" Markdown
" Plug 'iamcco/markdown-preview.nvim', {'do': 'cd app && yarn install'}

" Rego
" Plug 'tsandall/vim-rego'

" Github
Plug 'yasuhiroki/github-actions-yaml.vim'

Plug 'lukas-reineke/indent-blankline.nvim'

endif
call plug#end()

" set grepprg=rg\ --vimgrep\ --no-config\ --hidden\ --ignore-case\ --glob='!node_modules/*'\ --glob='!**/*.git/*'\ --glob='!**/*dist/*'\ --glob='!**/*vendor/*'\ --max-columns=210
set grepprg=rg\ --vimgrep\ --max-columns=210

if !has('gui_running') && &term =~ '\%(screen\|tmux\)'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set termguicolors

" theme
colorscheme nord
" colorscheme onehalflight

" use system clipboard
if has('nvim')
set clipboard+=unnamedplus
else
set clipboard=unnamed
endif

" Add missing cut feature
nnoremap d "_d
" vnoremap d "_d
nnoremap x "_x
" vnoremap x "_x

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

" File explorer
let g:netrw_banner = 0
let g:netrw_keepdir = 0
let g:netrw_list_hide = '\.\.\/,\.\/' " hide ./ and ../

" https://vi.stackexchange.com/questions/19003/try-catch-with-rexplore
fu! OpenExplorer()
    try
        silent :Rex
    catch
        :Ex
    endtry
endfu
nmap <silent> - :call OpenExplorer()<cr>

if has('nvim')
" python
" autocmd FileType python let b:coc_root_patterns = ['.git', '.env', 'venv', '.venv', 'setup.cfg', 'setup.py', 'pyproject.toml', 'pyrightconfig.json']

" vim-go
let g:go_fmt_command = "goimports"

" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0

lua <<EOF
local lsp_zero = require('lsp-zero')
local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()
local cmp_format = require('lsp-zero').cmp_format({details = true})
local lspconfig = require('lspconfig')

require("ibl").setup()


lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({buffer = bufnr})
end)

-- require'lspconfig'.terraform_lsp.setup{}
lspconfig.terraformls.setup{}
lspconfig.gopls.setup{}
lspconfig.jsonls.setup{}
lspconfig.pyright.setup{}
lspconfig.ts_ls.setup{}
lspconfig.regal.setup{}

-- Ruby
-- lspconfig.rubocop.setup{}
lspconfig.ruby_lsp.setup{}
-- lspconfig.sorbet.setup{}
-- lspconfig.solargraph.setup{}

--
-- require'lspconfig'.yamlls.setup{}
lspconfig.helm_ls.setup {
  settings = {
    ['helm-ls'] = {
      yamlls = {
        path = "yaml-language-server",
      }
    }
  }
}
lspconfig.bashls.setup{}
lspconfig.dartls.setup{}

require('copilot').setup({
  suggestion = {enabled = false},
  panel = {enabled = false},
})
require('copilot_cmp').setup()


cmp.setup({
  sources = {
    {name = 'nvim_lsp'},
    {name = 'copilot'},
    {name = 'rg'},
    {name = 'buffer'},
    {name = 'nvim_lsp_signature_help'},
    {name = 'path'},
  },
  formatting = cmp_format,
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({
      select = false,
      behavior = cmp.ConfirmBehavior.Replace,
    }),
    ['<Tab>'] = cmp_action.luasnip_supertab(),
    ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
  }),
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
})
EOF

endif
