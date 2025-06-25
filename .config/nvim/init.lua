-- same this in .vimrc
-- set runtimepath^=~/.vim runtimepath+=~/.vim/after
-- let &packpath=&runtimepath
-- source ~/.vimrc
vim.opt.runtimepath:prepend("~/.vim")
vim.opt.runtimepath:append("~/.vim/after")
vim.opt.packpath = vim.opt.runtimepath:get()
vim.cmd("source ~/.vimrc")

local lsp_zero = require("lsp-zero")
local cmp = require("cmp")
local cmp_action = require("lsp-zero").cmp_action()
local cmp_format = require("lsp-zero").cmp_format({ details = true })
local lspconfig = require("lspconfig")

-- indent lines
require("ibl").setup()

lsp_zero.on_attach(function(client, bufnr)
	-- see :help lsp-zero-keybindings
	-- to learn the available actions
	lsp_zero.default_keymaps({ buffer = bufnr })
end)

-- require'lspconfig'.terraform_lsp.setup{}
lspconfig.terraformls.setup({})
lspconfig.gopls.setup({})
lspconfig.jsonls.setup({})
lspconfig.pyright.setup({})
lspconfig.ts_ls.setup({})
lspconfig.eslint.setup({})
lspconfig.regal.setup({})

-- Ruby
-- lspconfig.rubocop.setup{}
lspconfig.ruby_lsp.setup({})
-- lspconfig.sorbet.setup{}
-- lspconfig.solargraph.setup{}

-- require'lspconfig'.yamlls.setup{}
lspconfig.helm_ls.setup({
	settings = {
		["helm-ls"] = {
			yamlls = {
				path = "yaml-language-server",
			},
		},
	},
})

lspconfig.bashls.setup({})
lspconfig.dartls.setup({})

local claude_model = "claude-sonnet-4"

require("copilot").setup({
	copilot_model = claude_model,
	panel = {
		auto_refresh = true,
	},
	suggestion = {
		auto_trigger = true,
	},
})
require("copilot_cmp").setup()
require("CopilotChat").setup({
	model = claude_model,
})

cmp.setup({
	sources = {
		{ name = "nvim_lsp" },
		{ name = "copilot" },
		{ name = "rg" },
		{ name = "path" },
		{ name = "nvim_lsp_signature_help" },
		-- {name = "buffer"},
	},
	formatting = cmp_format,
	mapping = cmp.mapping.preset.insert({
		["<CR>"] = cmp.mapping.confirm({
			select = false,
			behavior = cmp.ConfirmBehavior.Replace,
		}),
		["<Tab>"] = cmp_action.luasnip_supertab(),
		["<S-Tab>"] = cmp_action.luasnip_shift_supertab(),
	}),
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
})
