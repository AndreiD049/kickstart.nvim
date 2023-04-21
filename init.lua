---
--- VISUAL
---
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.termguicolors = true

vim.g.netrw_keepdir = 0

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smarttab = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.clipboard:append('unnamedplus')

--
-- SHELL
--
vim.opt.shell = vim.fn.has('win32') == 1 and 'pwsh' or 'zsh'
if vim.fn.has('win32') > 0 then
	vim.opt.shellcmdflag =
	'-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
	vim.opt.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
	vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
	vim.opt.shellquote = ''
	vim.opt.shellxquote = ''
end

--
-- KEYMAPS
--
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { silent = true })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

--
-- PLGINS
--

-- initializing lazy.nvim (https://github.com/folke/lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
	-- Colorscheme
	{
		"rebelot/kanagawa.nvim",
	},
	-- WHICH-KEY
	{ 'folke/which-key.nvim', opts = {} },
	{
		"folke/tokyonight.nvim",
		config = function()
			vim.cmd.colorscheme("tokyonight")
		end
	},
	-- LSP
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"williamboman/mason.nvim",
				config = true
			},
			"williamboman/mason-lspconfig.nvim",
			{
				"hrsh7th/nvim-cmp",
				dependencies = { "hrsh7th/cmp-nvim-lsp", "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip" }
			}
		}
	},
	-- TELESCOPE
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim" }
	},
	{
		"folke/neodev.nvim"
	},
	-- TREESITTER
	{
		'nvim-treesitter/nvim-treesitter',
		dependencies = {
			'nvim-treesitter/nvim-treesitter-textobjects',
		},
		build = ":TSUpdate",
	},
})

require 'neodev'.setup {}

--
-- LSP SERVERS & SETUP
--

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require 'cmp_nvim_lsp'.default_capabilities(capabilities)

-- Runs when LSP server attaches
local on_attach = function(_, bufnr)
	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
	nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

	nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
	nmap('ge', function() vim.diagnostic.open_float {} end, '[G]et [D]iagnostics');
	nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
	nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
	nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
	nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
	nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

	-- See `:help K` for why this keymap
	nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
	nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
		vim.lsp.buf.format()
	end, { desc = 'Format current buffer with LSP' })
end

local servers = {
	lua_ls = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false }
		}
	},
	clangd = {},
	tsserver = {}
}

local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
	ensure_installed = vim.tbl_keys(servers),
	automatic_installation = false
}

mason_lspconfig.setup_handlers {
	function(server_name)
		require("lspconfig")[server_name].setup {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = servers[server_name],
		}
	end,
}

--
-- COMPLETION
--

local cmp = require 'cmp'
local luasnip = require 'luasnip'

cmp.setup {
	snippet = {
		expand = function(args)
			require 'luasnip'.lsp_expand(args.body)
		end
	},
	mapping = cmp.mapping.preset.insert({
		['<C-d>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete {},
		['<CR>'] = cmp.mapping.confirm {
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		},
		['<Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { 'i', 's' }),
		['<S-Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { 'i', 's' }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" }
	})
}

--
-- TELESCOPE
--
local telescope = require 'telescope'

telescope.setup {}
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<leader>fd', function() require('telescope.builtin').diagnostics({ root_dir = true }) end, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>/', function()
	require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
		winblend = 10,
		previewer = false
	})
end, { desc = "[/] Fuzzy find in current buffer" })

--
-- TREESITTER
--

require 'nvim-treesitter.configs'.setup {
	ensure_installed = { 'c', 'cpp', 'lua', 'rust', 'tsx', 'typescript', 'vimdoc', 'vim' },
	auto_install = false,
	highlight = { enable = true },
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<c-s>",
			node_incremental = "<c-s>",
			scope_incremental = "<c-z>",
			node_decremental = "<c-d>"
		}
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				['aa'] = '@parameter.outer',
				['ia'] = '@parameter.inner',
				['af'] = '@function.outer',
				['if'] = '@function.inner',
				['ac'] = '@class.outer',
				['ic'] = '@class.inner',
			}
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				[']m'] = '@function.outer',
				[']]'] = '@class.outer',
			},
			goto_next_end = {
				[']M'] = '@function.outer',
				[']['] = '@class.outer',
			},
			goto_previous_start = {
				['[m'] = '@function.outer',
				['[['] = '@class.outer',
			},
			goto_previous_end = {
				['[M'] = '@function.outer',
				['[]'] = '@class.outer',
			},
		},
	}
}
