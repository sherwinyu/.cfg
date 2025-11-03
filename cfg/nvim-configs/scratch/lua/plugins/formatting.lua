-- Formatting with conform.nvim
return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				yaml = { "prettier" },
				lua = { "stylua" },
			},
			-- Format on save (optional - can enable/disable)
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		})

		-- Manual format keymap
		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range" })
	end,
}
