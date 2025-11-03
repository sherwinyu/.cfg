-- Auto-install formatters and linters via Mason
return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	dependencies = { "williamboman/mason.nvim" },
	config = function()
		require("mason-tool-installer").setup({
			ensure_installed = {
				-- Formatters
				"prettier", -- JavaScript/TypeScript/React formatter
				"stylua", -- Lua formatter

				-- Linters
				"eslint_d", -- Fast ESLint daemon for JS/TS
			},
			auto_update = false,
			run_on_start = true,
		})
	end,
}
