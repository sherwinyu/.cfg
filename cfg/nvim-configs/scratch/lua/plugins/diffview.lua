return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory" },
	keys = {
		{ "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open (vs index)" },
		{
			"<leader>dc",
			function()
				local diff_base = require("mylib.diff_base")
				local root = diff_base.repo_root()
				require("fzf-lua").git_branches({
					prompt = "Diff base> ",
					actions = {
						["default"] = function(selected)
							if not selected[1] then
								return
							end
							-- strip the leading "* " (current branch) or "+ " (checked out in
							-- another worktree) marker that `git branch --all` prefixes lines with
							local branch = selected[1]:match("^[%*%+]?%s*(%S+)")
							diff_base.remember(root, branch)
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
				local diff_base = require("mylib.diff_base")
				local root = diff_base.repo_root()
				require("fzf-lua").git_commits({
					prompt = "Diff base commit> ",
					actions = {
						["default"] = function(selected)
							if not selected[1] then
								return
							end
							local hash = selected[1]:match("%S+")
							diff_base.remember(root, hash)
							vim.cmd("DiffviewOpen " .. hash)
						end,
					},
				})
			end,
			desc = "Diffview: pick base commit",
		},
		{
			"<leader>dv",
			function()
				require("mylib.diff_base").open_current_file()
			end,
			desc = "Diffview: current file vs chosen base",
		},
		{
			"<leader>db",
			function()
				require("mylib.diff_base").apply_to_current_file()
			end,
			desc = "Show hunks vs chosen diff base",
		},
		{
			"<leader>dB",
			function()
				require("mylib.diff_base").reset_current_file()
			end,
			desc = "Show hunks vs index again",
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
