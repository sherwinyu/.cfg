return {
	{
		"f-person/auto-dark-mode.nvim",
		opts = {
			update_interval = 1000,
			set_dark_mode = function()
				vim.api.nvim_set_option_value("background", "dark", {})
				vim.cmd("colorscheme gruvbox")
			end,
			set_light_mode = function()
				vim.api.nvim_set_option_value("background", "light", {})
				vim.cmd("colorscheme gruvbox")
			end,
		},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "auto", -- Auto-detect system mode
			})
			vim.cmd("colorscheme catppuccin")
		end,
	},
	-- {
	-- 	"folke/tokyonight.nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	opts = {},
	-- 	config = function()
	-- 		require("tokyonight").setup({
	-- 			style = "moon", -- Use your preferred style: night, storm, or day
	-- 			on_highlights = function(hl, colors)
	-- 				-- Increase the contrast of the visual selection
	-- 				hl.Visual = {
	-- 					fg = "#FFFFFF",
	-- 					bg = colors.bg_visual,
	-- 				}
	-- 			end,
	-- 			on_colors = function()
	-- 				-- colors.bg_statusline = colors.bg_statusline:lighten(0.1)
	-- 			end,
	-- 		})
	-- 		vim.cmd("colorscheme tokyonight-moon")
	-- 	end,
	-- },
}
