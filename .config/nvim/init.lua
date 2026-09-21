-- same this in .vimrc
-- set runtimepath^=~/.vim runtimepath+=~/.vim/after
-- let &packpath=&runtimepath
-- source ~/.vimrc
vim.opt.runtimepath:prepend("~/.vim")
vim.opt.runtimepath:append("~/.vim/after")
vim.opt.packpath = vim.opt.runtimepath:get()
vim.cmd("source ~/.vimrc")

-- Disable unused providers to suppress warnings
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Fix GBrowse netrw#BrowseX error (Neovim 0.10+)
vim.api.nvim_create_user_command("Browse", function(opts)
	vim.ui.open(opts.fargs[1])
end, { nargs = 1 })

-- Markdown: treesitter highlighting (render-markdown reads these queries) and
-- in-buffer rendering. Browser preview via :MarkdownPreview (markdown-preview.nvim).
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(event)
		vim.treesitter.start()
		vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>",
			{ buffer = event.buf, desc = "Toggle markdown browser preview" })
	end,
})
-- pcall so a fresh checkout (pre-:PlugInstall) still starts cleanly
local rm_ok, render_markdown = pcall(require, "render-markdown")
if rm_ok then
	render_markdown.setup({})
end

-- indent-blankline (ibl) is set up asynchronously in load_completion_stack()
-- below; it pulls in treesitter, so we keep it off the startup path.

-- LSP keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local opts = { buffer = event.buf, remap = false }
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
	end,
})

-- LSP Server configurations using vim.lsp.config (Neovim 0.11+)
-- Helper function to check if executable exists
local function executable_exists(name)
	return vim.fn.executable(name) == 1
end

-- Go (always configure, check at enable time)
vim.lsp.config.gopls = {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { "go.work", "go.mod", ".git" },
	settings = {
		gopls = {
			completeUnimported = true,
			usePlaceholders = true,
			analyses = {
				unusedparams = true,
			},
		},
	},
}

-- Terraform
vim.lsp.config.terraformls = {
	cmd = { "terraform-ls", "serve" },
	filetypes = { "terraform", "terraform-vars" },
	root_markers = { ".terraform", ".git" },
}

-- JSON
vim.lsp.config.jsonls = {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
}

-- Python
vim.lsp.config.pyright = {
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" },
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				useLibraryCodeForTypes = true,
			},
		},
	},
}

-- TypeScript/JavaScript
vim.lsp.config.ts_ls = {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
}

-- ESLint
vim.lsp.config.eslint = {
	cmd = { "vscode-eslint-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "svelte", "astro" },
	root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc.json", "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs" },
}

-- Rego (Open Policy Agent)
vim.lsp.config.regal = {
	cmd = { "regal", "language-server" },
	filetypes = { "rego" },
	root_markers = { ".regal", ".git" },
}

-- Ruby
vim.lsp.config.ruby_lsp = {
	cmd = { "ruby-lsp" },
	filetypes = { "ruby" },
	root_markers = { "Gemfile", ".git" },
}

-- Helm
vim.lsp.config.helm_ls = {
	cmd = { "helm_ls", "serve" },
	filetypes = { "helm" },
	root_markers = { "Chart.yaml" },
	settings = {
		["helm-ls"] = {
			yamlls = {
				path = "yaml-language-server",
			},
		},
	},
}

-- Bash
vim.lsp.config.bashls = {
	cmd = { "bash-language-server", "start" },
	filetypes = { "sh", "bash" },
}

-- Dart
vim.lsp.config.dartls = {
	cmd = { "dart", "language-server", "--protocol=lsp" },
	filetypes = { "dart" },
	root_markers = { "pubspec.yaml", ".git" },
}

-- Enable only LSP servers that are installed
local servers_to_enable = {}
local server_executables = {
	gopls = "gopls",
	terraformls = "terraform-ls",
	jsonls = "vscode-json-language-server",
	pyright = "pyright-langserver",
	ts_ls = "typescript-language-server",
	eslint = "vscode-eslint-language-server",
	regal = "regal",
	ruby_lsp = "ruby-lsp",
	helm_ls = "helm_ls",
	bashls = "bash-language-server",
	dartls = "dart",
}

for server, executable in pairs(server_executables) do
	if executable_exists(executable) then
		table.insert(servers_to_enable, server)
	end
end

if #servers_to_enable > 0 then
	vim.lsp.enable(servers_to_enable)
end

-- ---------------------------------------------------------------------------
-- Async plugin loading: defer the completion + Copilot stack until AFTER the UI
-- is drawn. copilot.lua spawns a Node language server on setup(), so keeping it
-- off the startup path is what makes nvim open instantly (including Claude's
-- Ctrl-g editor). LSP servers (vim.lsp.enable above) stay synchronous, so they
-- still attach to the first buffer; only completion/Copilot arrive a beat later.
-- ---------------------------------------------------------------------------
local function load_completion_stack()
	-- Pull the lazy (vim-plug {'on': []}) plugins onto the runtimepath first.
	vim.fn["plug#load"]("LuaSnip", "copilot.lua", "copilot-cmp", "CopilotChat.nvim", "indent-blankline.nvim")
	require("ibl").setup()

	local cmp = require("cmp")
	local lsp_zero = require("lsp-zero")
	local cmp_action = lsp_zero.cmp_action()
	local cmp_format = lsp_zero.cmp_format({ details = true })

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
end

-- Fire once, right after the first UI paint. The tiny delay lets the window
-- appear before Node spins up; everything above stays on the fast startup path.
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		vim.defer_fn(load_completion_stack, 30)
	end,
})
