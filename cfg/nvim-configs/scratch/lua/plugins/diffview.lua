return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory" },
	keys = {
		{ "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open (vs index)" },
		{
			"<leader>dc",
			function()
				require("fzf-lua").git_branches({
					prompt = "Diff base> ",
					actions = {
						["default"] = function(selected)
							local branch = selected[1]:match("%S+")
							vim.cmd("DiffviewOpen " .. branch)
						end,
					},
				})
			end,
			desc = "Diffview: pick base branch",
		},
		{
			"<leader>dC",
			function()
				require("fzf-lua").git_commits({
					prompt = "Diff base commit> ",
					actions = {
						["default"] = function(selected)
							local hash = selected[1]:match("%S+")
							vim.cmd("DiffviewOpen " .. hash)
						end,
					},
				})
			end,
			desc = "Diffview: pick base commit",
		},
		{ "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
		{ "<leader>dH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: branch history" },
		{ "<leader>dq", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
	},
	opts = {
		enhanced_diff_hl = true,
		view = {
			default = { layout = "diff2_horizontal" },
		},
	},
}
