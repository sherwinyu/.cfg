-- UI plugins: colorscheme, statusline, notifications
return {
	-- Tokyo Night colorscheme
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "moon",
			on_highlights = function(hl, colors)
				hl.Visual = {
					fg = "#FFFFFF",
					bg = colors.bg_visual,
				}
			end,
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd("colorscheme tokyonight-moon")
		end,
	},

	-- Color highlighting
	{
		"brenoprata10/nvim-highlight-colors",
		opts = {
			render = "virtual",
		},
	},

	-- Lualine statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "auto",
				globalstatus = true,
			},
			sections = {
				lualine_a = {
					{
						"mode",
						fmt = function(s)
							local mode_map = {
								["NORMAL"] = "N",
								["INSERT"] = "I",
								["VISUAL"] = "V",
								["V-LINE"] = "VL",
								["V-BLOCK"] = "VB",
								["COMMAND"] = "!",
								["REPLACE"] = "R",
								["TERMINAL"] = "T",
							}
							return mode_map[s] or s
						end,
					},
				},
				lualine_b = { "branch" },
				lualine_c = {
					{ "diagnostics" },
					{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
					{ "filename", path = 1 },
				},
				lualine_x = {},
				lualine_y = {
					{ "progress", separator = " ", padding = { left = 1, right = 0 } },
					{ "location", padding = { left = 0, right = 1 } },
				},
				lualine_z = {
					function()
						return " " .. os.date("%R")
					end,
				},
			},
			extensions = { "neo-tree", "lazy" },
		},
	},

	-- Notifications
	{
		"rcarriga/nvim-notify",
		keys = {
			{ "<leader>in", "<cmd>Telescope notify<cr>", desc = "Show notifications" },
		},
		opts = {
			timeout = 3000,
		},
	},
}
