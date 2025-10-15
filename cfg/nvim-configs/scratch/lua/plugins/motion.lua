-- Motion plugins: CamelCase, Leap
local map = vim.keymap.set

return {
	-- CamelCase motion
	{
		"bkad/CamelCaseMotion",
		lazy = false,
		config = function()
			local map = vim.keymap.set
			-- Disable default mappings
			vim.g.camelcasemotion_key = '<leader>'

			-- Text object mappings - use 'x' as shorthand for inner camel segment
			-- Usage: dx (delete segment), cx (change segment)
			map("o", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
			map("x", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
		end,
	},

	-- Leap motion
	{
		"ggandor/leap.nvim",
		keys = {
			{ "s", mode = { "n" }, desc = "Leap" },
			{ "S", mode = { "n", "x", "o" }, desc = "Leap Backward to" },
			{ "<localleader>s", mode = { "n", "x", "o" }, desc = "Leap from Windows" },
		},
		config = function()
			map("n", "s", "<Plug>(leap)")
			map("n", "<localleader>s", "<Plug>(leap-from-window)")
			map({ "x", "o" }, "z", "<Plug>(leap-forward)")
			map({ "x", "o" }, "Z", "<Plug>(leap-backward)")
		end,
	},
}
