local map = vim.keymap.set
return {
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
