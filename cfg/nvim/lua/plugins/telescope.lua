opts = function()
	local actions = require("telescope.actions")

	local open_with_trouble = function(...)
		return require("trouble.sources.telescope").open(...)
	end
	local find_files_no_ignore = function()
		local action_state = require("telescope.actions.state")
		local line = action_state.get_current_line()
		LazyVim.pick("find_files", { no_ignore = true, default_text = line })()
	end
	local find_files_with_hidden = function()
		local action_state = require("telescope.actions.state")
		local line = action_state.get_current_line()
		LazyVim.pick("find_files", { hidden = true, default_text = line })()
	end

	local function find_command()
		if 1 == vim.fn.executable("rg") then
			return { "rg", "--files", "--no-require-git", "--color", "never", "-g", "!.git" }
		elseif 1 == vim.fn.executable("fd") then
			return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
		elseif 1 == vim.fn.executable("fdfind") then
			return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
		elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
			return { "find", ".", "-type", "f" }
		elseif 1 == vim.fn.executable("where") then
			return { "where", "/r", ".", "*" }
		end
	end

	return {
		defaults = {
			selection_caret = " ",
			-- open files in the first window that is an actual file.
			-- use the current window if no other window is available.
			get_selection_window = function()
				local wins = vim.api.nvim_list_wins()
				table.insert(wins, 1, vim.api.nvim_get_current_win())
				for _, win in ipairs(wins) do
					local buf = vim.api.nvim_win_get_buf(win)
					if vim.bo[buf].buftype == "" then
						return win
					end
				end
				return 0
			end,
			mappings = {
				i = {
					["<c-t>"] = open_with_trouble,
					["<a-t>"] = open_with_trouble,
					["<a-i>"] = find_files_no_ignore,
					["<a-h>"] = find_files_with_hidden,
					["<c-down>"] = actions.cycle_history_next,
					["<c-up>"] = actions.cycle_history_prev,
					["<c-f>"] = actions.preview_scrolling_down,
					["<c-b>"] = actions.preview_scrolling_up,
					["<c-j>"] = actions.move_selection_next,
					["<c-k>"] = actions.move_selection_previous,
					["<m-f>"] = { type = "command", "<c-o>w" },
					["<m-b>"] = { type = "command", "<c-o>b" },
					["<c-a>"] = { type = "command", "<c-o>0" },
					["<c-e>"] = { type = "command", "<c-o>$" },
					["<space><space>"] = actions.close,
					["kj"] = actions.close,
				},
				n = {
					["q"] = actions.close,
					["jk"] = actions.close,
				},
			},
		},
		pickers = {
			find_files = {
				find_command = find_command,
				hidden = true,
			},
		},
	}
end
return {
	{
		"nvim-telescope/telescope.nvim",
		opts = opts,
	},
}
