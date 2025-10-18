-- Litee.nvim - VS Code-style call hierarchy and symbol panels
return {
	-- Core litee library
	{
		"ldelossa/litee.nvim",
		event = "VeryLazy",
		opts = {
			notify = { enabled = false },
			panel = {
				orientation = "right",
				panel_size = 50,
			},
		},
		config = function(_, opts)
			require("litee.lib").setup(opts)
		end,
	},

	-- Call hierarchy integration
	{
		"ldelossa/litee-calltree.nvim",
		dependencies = "ldelossa/litee.nvim",
		event = "VeryLazy",
		opts = {
			on_open = "panel", -- Open in side panel
			map_resize_keys = false,
		},
		config = function(_, opts)
			require("litee.calltree").setup(opts)
		end,
		keys = {
			{
				"<leader>ch",
				function()
					require("litee.calltree").open_to()
				end,
				desc = "LSP: Call hierarchy (tree)",
			},
			{
				"<leader>cH",
				function()
					require("litee.calltree").close()
				end,
				desc = "LSP: Close call hierarchy",
			},
		},
	},

	-- Symbol outline integration (optional)
	{
		"ldelossa/litee-symboltree.nvim",
		dependencies = "ldelossa/litee.nvim",
		event = "VeryLazy",
		opts = {
			on_open = "panel",
		},
		config = function(_, opts)
			require("litee.symboltree").setup(opts)
		end,
		keys = {
			{
				"<leader>cs",
				function()
					require("litee.symboltree").open_to()
				end,
				desc = "LSP: Symbol tree",
			},
		},
	},
}
