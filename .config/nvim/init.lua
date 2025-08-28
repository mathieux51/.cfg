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

	-- Additional keymaps
	local opts = { buffer = bufnr, remap = false }
	vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
	vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
	vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
	vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
	vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
	vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
	vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
	vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
	vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
	vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end)

-- LSP Server configurations
-- Terraform
lspconfig.terraformls.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

-- Go
lspconfig.gopls.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = {
				unusedparams = true,
			},
		},
	},
})

-- JSON
lspconfig.jsonls.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

-- Python
lspconfig.pyright.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				useLibraryCodeForTypes = true,
			},
		},
	},
})

-- TypeScript/JavaScript
lspconfig.ts_ls.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

lspconfig.eslint.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

-- Rego (Open Policy Agent)
lspconfig.regal.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

-- Ruby
lspconfig.ruby_lsp.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

-- Helm
lspconfig.helm_ls.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
	settings = {
		["helm-ls"] = {
			yamlls = {
				path = "yaml-language-server",
			},
		},
	},
})

-- Bash
lspconfig.bashls.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

-- Dart
lspconfig.dartls.setup({
	on_attach = lsp_zero.on_attach,
	capabilities = lsp_zero.get_capabilities(),
})

-- Claude via Copilot configuration
local claude_model = "claude-3.5-sonnet"

require("copilot").setup({
	suggestion = {
		enabled = false,
		auto_trigger = false,
		debounce = 75,
		keymap = {
			accept = "<M-l>",
			accept_word = false,
			accept_line = false,
			next = "<M-]>",
			prev = "<M-[>",
			dismiss = "<C-]>",
		},
	},
	panel = {
		enabled = true,
		auto_refresh = true,
		keymap = {
			jump_prev = "[[",
			jump_next = "]]",
			accept = "<CR>",
			refresh = "gr",
			open = "<M-CR>",
		},
		layout = {
			position = "bottom",
			ratio = 0.4,
		},
	},
	filetypes = {
		yaml = false,
		markdown = false,
		help = false,
		gitcommit = false,
		gitrebase = false,
		hgcommit = false,
		svn = false,
		cvs = false,
		["."] = false,
	},
	copilot_node_command = "node",
	server_opts_overrides = {},
})

require("copilot_cmp").setup()

require("CopilotChat").setup({
	model = claude_model,
	debug = false,
	show_help = true,
	question_header = "## User ",
	answer_header = "## Claude ",
	error_header = "## Error ",
	window = {
		layout = "vertical",
		width = 0.5,
		height = 0.5,
		relative = "editor",
		border = "rounded",
	},
})

cmp.setup({
	sources = {
		{ name = "nvim_lsp" },
		{ name = "copilot" },
		{ name = "rg" },
		{ name = "path" },
		{ name = "nvim_lsp_signature_help" },
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
