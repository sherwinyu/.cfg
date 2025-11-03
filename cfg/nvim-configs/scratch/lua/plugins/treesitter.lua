-- Treesitter configuration
return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "tsx", "python" },
				sync_install = false,
				auto_install = true, -- Automatically install missing parsers
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
}
