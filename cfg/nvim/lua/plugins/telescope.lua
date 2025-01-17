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
		keys = {
			{
				"<leader>,",
				"<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
				desc = "Switch Buffer",
			},
			{ "<leader>/", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
			{ "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },
			{ "<leader><space>", false, LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
			{ "<leader>t", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
			-- find
			{ "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
			{ "<localleader>b", ":lua telescope_buffer_picker()<cr>", desc = "Jump to Recent Buffer" },
			{ "<localleader>vf", LazyVim.pick.config_files(), desc = "Vim Config: Find Config Files" },
			{ "<leader>ff", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
			{ "<leader>fF", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
			{ "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
			{ "<leader>fR", LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
			-- git
			{ "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Commits" },
			{ "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Status" },
			-- search
			{ '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
			{ "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "Auto Commands" },
			{ "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
			{ "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "Command History" },
			{ "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
			{ "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics" },
			{ "<leader>sD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics" },
			{ "<leader>sg", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
			{ "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
			{ "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
			{ "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Search Highlight Groups" },
			{ "<leader>sj", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
			{ "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
			{ "<leader>sl", "<cmd>Telescope loclist<cr>", desc = "Location List" },
			{ "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
			{ "<leader>sm", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
			{ "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
			{ "<leader>sr", "<cmd>Telescope resume<cr>", desc = "Telescope Resume" },
			{ "<leader>sq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix List" },
			{ "<leader>sw", LazyVim.pick("grep_string", { word_match = "-w" }), desc = "Word (Root Dir)" },
			{ "<leader>sW", LazyVim.pick("grep_string", { root = false, word_match = "-w" }), desc = "Word (cwd)" },
			{ "<leader>sw", LazyVim.pick("grep_string"), mode = "v", desc = "Selection (Root Dir)" },
			{ "<leader>sW", LazyVim.pick("grep_string", { root = false }), mode = "v", desc = "Selection (cwd)" },
			{ "<leader>uC", LazyVim.pick("colorscheme", { enable_preview = true }), desc = "Colorscheme with Preview" },
			{
				"<leader>ss",
				function()
					require("telescope.builtin").lsp_document_symbols({
						symbols = LazyVim.config.get_kind_filter(),
					})
				end,
				desc = "Goto Symbol",
			},
			{
				"<leader>sS",
				function()
					require("telescope.builtin").lsp_dynamic_workspace_symbols({
						symbols = LazyVim.config.get_kind_filter(),
					})
				end,
				desc = "Goto Symbol (Workspace)",
			},
		},
	},
}
