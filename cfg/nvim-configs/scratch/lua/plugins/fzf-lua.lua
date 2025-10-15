-- fzf-lua configuration
return {
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<leader>fz", "<cmd>FzfLua<cr>", desc = "FzfLua" },
			{ "<leader>fzf", "<cmd>FzfLua files<cr>", desc = "FzfLua files" },
			{ "<leader>fzg", "<cmd>FzfLua live_grep<cr>", desc = "FzfLua live grep" },
			{ "<leader>fzb", "<cmd>FzfLua buffers<cr>", desc = "FzfLua buffers" },
			{ "<leader>fzh", "<cmd>FzfLua help_tags<cr>", desc = "FzfLua help" },
			{ "<leader>fzo", "<cmd>FzfLua oldfiles<cr>", desc = "FzfLua recent files" },
		},
		opts = {
			winopts = {
				height = 0.85,
				width = 0.80,
				preview = {
					layout = "vertical",
					vertical = "down:45%",
				},
			},
		},
	},
}
