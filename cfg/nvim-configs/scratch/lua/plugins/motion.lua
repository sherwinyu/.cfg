-- Motion plugins: CamelCase, Leap
local map = vim.keymap.set

return {
	-- CamelCase motion
	{
		"bkad/CamelCaseMotion",
		config = function()
			map("n", "gw", "<Plug>CamelCaseMotion_w", { silent = true })
			map("n", "gb", "<Plug>CamelCaseMotion_b", { silent = true })
			map("n", "ge", "<Plug>CamelCaseMotion_e", { silent = true })
			map("o", "gw", "<Plug>CamelCaseMotion_w", { silent = true })
			map("o", "gb", "<Plug>CamelCaseMotion_b", { silent = true })
			map("o", "ge", "<Plug>CamelCaseMotion_e", { silent = true })

			map("o", "X", "iW", { silent = true })
			map("o", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
			map("o", "igw", "<Plug>CamelCaseMotion_iw", { silent = true })
			map("o", "ige", "<Plug>CamelCaseMotion_ie", { silent = true })
			map("o", "igb", "<Plug>CamelCaseMotion_ib", { silent = true })

			map("v", "X", "iW", { silent = true })
			map("v", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
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
