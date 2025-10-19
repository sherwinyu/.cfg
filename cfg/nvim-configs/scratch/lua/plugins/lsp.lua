-- LSP configuration
return {
	-- Mason setup (must load first)
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},

	-- Mason-lspconfig bridge
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "ts_ls" },
				automatic_installation = true,
				automatic_enable = false, -- Disable automatic vim.lsp.enable() calls
			})
		end,
	},

	-- LSP config
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local fzf = require("fzf-lua")

			-- Configure Lua LSP for Neovim
			lspconfig.lua_ls.setup({
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
						telemetry = {
							enable = false,
						},
					},
				},
			})

			-- Configure TypeScript LSP
			lspconfig.ts_ls.setup({
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
				},
			})

			-- Key mappings
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
			vim.keymap.set("n", "gi", fzf.lsp_implementations, { desc = "Go to implementations" })
			vim.keymap.set("n", "gt", fzf.lsp_typedefs, { desc = "Go to type definition" })
			vim.keymap.set("n", "gr", fzf.lsp_references, { desc = "Go to references" })
			vim.keymap.set("n", "gh", vim.lsp.buf.hover, { desc = "Hover documentation" })
			vim.keymap.set("n", "gH", vim.lsp.buf.signature_help, { desc = "Signature help" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
			vim.keymap.set("n", "<leader>ds", fzf.lsp_document_symbols, { desc = "Document symbols" })
			vim.keymap.set("n", "<leader>ws", fzf.lsp_workspace_symbols, { desc = "Workspace symbols" })
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
			vim.keymap.set("n", "<leader>cd", fzf.diagnostics_document, { desc = "Document diagnostics" })
			vim.keymap.set("n", "<leader>cD", fzf.diagnostics_workspace, { desc = "Workspace diagnostics" })

			-- Override Neovim's default gr* mappings to use fzf where appropriate
			vim.keymap.set("n", "grr", fzf.lsp_references, { desc = "LSP: References (fzf)" })
			vim.keymap.set("n", "gri", fzf.lsp_implementations, { desc = "LSP: Implementations (fzf)" })
			vim.keymap.set("n", "grt", fzf.lsp_typedefs, { desc = "LSP: Type definitions (fzf)" })
			-- Keep gra and grn as-is (code action and rename don't benefit from fzf)
			vim.keymap.set("n", "gra", vim.lsp.buf.code_action, { desc = "LSP: Code action" })
			vim.keymap.set("x", "gra", vim.lsp.buf.code_action, { desc = "LSP: Code action" })
			vim.keymap.set("n", "grn", vim.lsp.buf.rename, { desc = "LSP: Rename" })

			-- Call hierarchy (navigable with fzf)
			vim.keymap.set("n", "<leader>ci", fzf.lsp_incoming_calls, { desc = "LSP: Incoming calls" })
			vim.keymap.set("n", "<leader>co", fzf.lsp_outgoing_calls, { desc = "LSP: Outgoing calls" })

			-- Source actions (TypeScript: organize imports, remove unused, etc.)
			vim.keymap.set("n", "<leader>cA", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source" },
						diagnostics = {},
					},
				})
			end, { desc = "Source actions (organize imports, etc.)" })

			vim.keymap.set("n", "<leader>cO", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.organizeImports" },
						diagnostics = {},
					},
				})
			end, { desc = "Organize imports" })

			vim.keymap.set("n", "<leader>cR", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = {
						only = { "source.removeUnused" },
						diagnostics = {},
					},
				})
			end, { desc = "Remove unused imports" })
		end,
	},
}
