-- Keymaps configuration
local map = vim.keymap.set

-- Escape mappings
map("i", "kj", "<Esc>", { noremap = true })
map("v", "<space><space>", "<Esc>", { noremap = true })
map("n", "<leader>v", "<c-v>", { noremap = true, desc = "Visual block" })
map("n", "<localleader>v", "<c-v>", { noremap = true, desc = "Visual block" })

-- Movement
map("n", "<localleader>h", "<cmd>set hlsearch!<CR>", { noremap = true, desc = "Clear search highlighting" })
map({ "n", "v", "o" }, "-", "^", { noremap = true })
map({ "n", "v", "o" }, "=", "$", { noremap = true })
map({ "n", "v", "o" }, "<c-a>", "^", { noremap = true })
map({ "n", "v", "o" }, "<c-e>", "$", { noremap = true })

-- Files: open / write / quit, rename, paths / lifecycle
map("n", "<LocalLeader>e", ":e ", { noremap = true })
map("n", "<LocalLeader>E", ":e <c-r>%", { noremap = true })
map("n", "<LocalLeader>fsa", ":saveas <c-r>%", { noremap = true })
map("n", "<Leader>w", ":w<CR>", { noremap = true })
map("n", "<Leader>q", ":q<CR>", { noremap = true })
map("n", "<Leader>.q", ":qa<CR>", { noremap = true, desc = "Quit all" })
map("n", "<LocalLeader>q", ":q<CR>", { noremap = true })
map("n", "<Leader>Q", ":qa", { noremap = true, desc = "Quit all" })

-- CopyFilePath
vim.api.nvim_create_user_command("CopyFilePath", function()
	local file_path = vim.fn.expand("%")
	vim.fn.setreg("+", file_path)
	print("Copied file path: " .. file_path)
end, {})
map("n", "<localleader>fc", "<cmd>CopyFilePath<cr>")

-- RenameFile
vim.api.nvim_create_user_command("RenameFile", function(args)
	local function ensure_directory_exists(path)
		local dir = vim.fn.fnamemodify(path, ":h")
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end
	local old_name = vim.fn.expand("%")
	local new_name = args.args

	if new_name == "" then
		print("Error: No new file name provided")
		return
	end

	ensure_directory_exists(new_name)

	local success, err = os.rename(old_name, new_name)
	if not success then
		print("Error renaming file: " .. err)
		return
	end

	vim.cmd("edit " .. new_name)
	vim.cmd("bdelete " .. old_name)
	print("Renamed file to: " .. new_name)
end, {
	nargs = 1,
	complete = "file",
})
map("n", "<localleader>fr", ":RenameFile <c-r>%", { desc = "Rename file", noremap = true })

-- Sourcing files
map("n", "<localLeader>vr", ":source %<CR>", { noremap = true, desc = "Vim Config: source file" })
map("n", "<localLeader>vf", ":source %<CR>", { noremap = true })

-- Search
map("n", "<leader>gn", ":set nohlsearch", { noremap = true, desc = "Clear search highlighting" })

-- Normal mode editing
local function returnToCursorAfterCommand(cmd)
	local pos = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", true)
	vim.api.nvim_win_set_cursor(0, pos)
end

map("n", "g,", function()
	returnToCursorAfterCommand("A,<Esc>")
end, { noremap = true, desc = "Insert comma at end of line" })

map("n", "<leader>j", "i<CR><Esc>k$", { noremap = true, desc = "Split line" })
map("n", "<leader>us", 'n"tyiw:%s/<C-r>//<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute" })
map("n", "<leader>uS", '"tyiw:s/<C-r>//<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute (line only)" })
map("v", "<leader>us", '"ty:%s/<C-r>t/<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute" })
map("v", "<leader>uS", '"ty:s/<C-r>t/<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute (line only)" })

map("n", "*", ":set hlsearch<CR>*N", { noremap = true })

-- Indent/outdent current line
map("n", ">", ">>", { noremap = true, desc = "Indent line" })
map("n", "<", "<<", { noremap = true, desc = "Outdent line" })

-- Indent/outdent in visual mode and reselect
map("v", ">", ">gv", { noremap = true, desc = "Indent and reselect" })
map("v", "<", "<gv", { noremap = true, desc = "Outdent and reselect" })

map("o", "x", "ie", { desc = "Word fragment" })

-- Moving lines / bubble up / bubbledown
map("n", "<c-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<c-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("i", "<c-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<c-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<c-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<c-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

-- Insert mode Editing
map("n", "<s-enter>", function()
	returnToCursorAfterCommand("O<Esc>")
end, { noremap = true, desc = "Gap line above" })

map("n", "<c-enter>", function()
	returnToCursorAfterCommand("O<Esc>")
end, { noremap = true, desc = "Gap line above" })

map("n", "<enter>", function()
	returnToCursorAfterCommand("o<Esc>")
end, { noremap = true, desc = "Gap line below" })

map("i", "<c-a>", "<c-o>^", { noremap = true, desc = "Move to start of line" })
map("i", "<c-e>", "<c-o>$", { noremap = true, desc = "Move to end of line" })
map("i", "<D-Right>", "<c-o>$", { noremap = true, desc = "Move to end of line" })
map("i", "<M-f>", "<c-o>w", { noremap = true, desc = "Move forward one word" })
map("i", "<M-b>", "<c-o>b", { noremap = true, desc = "Move back one word" })
map("i", "<M-BS>", "<c-w>", { noremap = true, desc = "Delete backward word" })
map("i", "<M-d>", "<c-o>de", { noremap = true, desc = "Delete forward word" })

-- Command mode
map("c", "<M-f>", "<c-right>", { noremap = true, desc = "Move forward one word" })
map("c", "<M-b>", "<c-left>", { noremap = true, desc = "Move backward one word" })
map("c", "<c-a>", "<Home>", { noremap = true, desc = "Move to start of line" })
map("c", "<c-e>", "<End>", { noremap = true, desc = "Move to end of line" })

-- Navigating in current windows
map("n", "<c-b>", "8k", { noremap = true, desc = "Scroll up" })
map("n", "<c-f>", "8j", { noremap = true, desc = "Scroll down" })

-- Window and tab management
map("n", "\\", "<c-w>w", { noremap = true, desc = "Next window" })
map("n", "|", "<c-w>W", { noremap = true, desc = "Prev window" })
-- Tab is reserved for Copilot NES suggestions
map("n", "<localleader>wm", "<c-w>", { noremap = true, desc = "Window mode" })

map("n", "<f1>", "1gt", { noremap = true })
map("n", "<f2>", "2gt", { noremap = true })
map("n", "<f3>", "3gt", { noremap = true })
map("n", "<f4>", "4gt", { noremap = true })
map("n", "<f5>", "5gt", { noremap = true })
map("n", "<f6>", "6gt", { noremap = true })

map("n", "<localleader>1", "1gt", { noremap = true })
map("n", "<localleader>2", "2gt", { noremap = true })
map("n", "<localleader>3", "3gt", { noremap = true })
map("n", "<localleader>4", "4gt", { noremap = true })
map("n", "<localleader>5", "5gt", { noremap = true })
map("n", "<localleader>6", "6gt", { noremap = true })

-- Tab navigation
map("n", "(", "gT", { noremap = true, desc = "Tab: next" })
map("n", ")", "gt", { noremap = true, desc = "Tab: previous" })
map("n", "<localleader>(", "<cmd>tabm -1<CR>", { noremap = true, desc = "Tab: move left" })
map("n", "<localleader>)", "<cmd>tabm +1<CR>", { noremap = true, desc = "Tab: move right" })

-- Tab lifecycle
map("n", "<c-t>", "<cmd>tabnew<CR>", { noremap = true })
map("n", "<localleader>tt", "<cmd>tabnew<CR>", { noremap = true, desc = "Tab: new" })
map("n", "<localleader>to", "<cmd>tabo<CR>", { noremap = true, desc = "Tab: Only -- Close all other tabs" })

-- Tab management commands
-- Rename current tab
vim.api.nvim_create_user_command("TabRename", function(args)
	local tabname = args.args
	if tabname == "" then
		print("Error: No tab name provided")
		return
	end
	vim.fn.settabvar(vim.fn.tabpagenr(), "tabby_tab_name", tabname)
	print("Tab renamed to: " .. tabname)
end, {
	nargs = 1,
	desc = "Rename current tab",
})
map("n", "<localleader>tr", ":TabRename ", { noremap = true, desc = "Tab: rename" })

-- Clone current tab (duplicate all windows to new tab)
vim.api.nvim_create_user_command("TabClone", function()
	-- Get all normal windows in current tab (exclude floating windows)
	local windows = vim.api.nvim_tabpage_list_wins(0)
	local win_info = {}

	-- Filter out floating windows and store buffer + position info
	for _, win in ipairs(windows) do
		local config = vim.api.nvim_win_get_config(win)
		-- Only include normal windows (not floating)
		if config.relative == "" then
			local pos = vim.api.nvim_win_get_position(win)
			table.insert(win_info, {
				bufnr = vim.api.nvim_win_get_buf(win),
				row = pos[1],
				col = pos[2],
				width = vim.api.nvim_win_get_width(win),
				height = vim.api.nvim_win_get_height(win),
			})
		end
	end

	-- If only one window, use simple tab split
	if #win_info == 1 then
		vim.cmd("tab split")
		print("Tab cloned (1 window)")
		return
	end

	-- Sort windows by position (top to bottom, left to right)
	table.sort(win_info, function(a, b)
		if a.row == b.row then
			return a.col < b.col
		end
		return a.row < b.row
	end)

	-- Create new tab with first buffer
	vim.cmd("tabnew")
	vim.cmd("buffer " .. win_info[1].bufnr)

	-- Recreate splits by detecting layout pattern
	for i = 2, #win_info do
		local prev = win_info[i - 1]
		local curr = win_info[i]

		-- Determine split direction based on position
		-- If row is same, it's a vertical split (side by side)
		-- If row is different, it's a horizontal split (top/bottom)
		if curr.row == prev.row then
			-- Vertical split (same row, different column)
			vim.cmd("vsplit")
		else
			-- Horizontal split (different row)
			vim.cmd("split")
		end

		vim.cmd("buffer " .. curr.bufnr)
	end

	-- Return to first window
	vim.cmd("1wincmd w")

	print("Tab cloned (" .. #win_info .. " windows)")
end, {
	desc = "Clone all windows to new tab",
})
map("n", "<localleader>tc", "<cmd>TabClone<cr>", { noremap = true, desc = "Tab: clone all windows" })

-- Pin buffer to all tabs (open in all tabs)
vim.api.nvim_create_user_command("TabPin", function()
	local current_buf = vim.fn.bufnr("%")
	local current_tab = vim.fn.tabpagenr()

	-- Open buffer in all tabs
	for tabnr = 1, vim.fn.tabpagenr("$") do
		if tabnr ~= current_tab then
			vim.cmd(tabnr .. "tabnext")
			vim.cmd("vsplit")
			vim.cmd("buffer " .. current_buf)
		end
	end

	-- Return to original tab
	vim.cmd(current_tab .. "tabnext")
	print("Buffer pinned to all tabs")
end, {
	desc = "Pin current buffer to all tabs",
})
map("n", "<localleader>tp", "<cmd>TabPin<cr>", { noremap = true, desc = "Tab: pin buffer to all tabs" })

map("n", "<left>", "<C-w>h", { noremap = true, desc = "Go to Left Window" })
map("n", "<down>", "<C-w>j", { noremap = true, desc = "Go to Lower Window" })
map("n", "<up>", "<C-w>k", { noremap = true, desc = "Go to Upper Window" })
map("n", "<right>", "<C-w>l", { noremap = true, desc = "Go to Right Window" })
map("n", "<M-.>", "<cmd>resize +2<cr>", { desc = "Window Resize: increase height" })
map("n", "<M-,>", "<cmd>resize -2<cr>", { desc = "Window Resize: decrease height" })
map("n", "<M-]>", "<cmd>vertical resize -2<cr>", { desc = "Window Resize: decrease width" })
map("n", "<M-[>", "<cmd>vertical resize +2<cr>", { desc = "Window Resize: increase width" })

map("n", "<localleader>wh", "<C-w>H", { noremap = true, desc = "Window Pane: Move left" })
map("n", "<localleader>wj", "<C-w>J", { noremap = true, desc = "Window Pane: Move down" })
map("n", "<localleader>wk", "<C-w>K", { noremap = true, desc = "Window Pane: Move up" })
map("n", "<localleader>wl", "<C-w>L", { noremap = true, desc = "Window Pane: Move right" })

map("n", "<localleader>wv", "<C-w>v", { noremap = true, desc = "Window pane: split vertical" })
map("n", "<localleader>ws", "<C-w>s", { noremap = true, desc = "Window pane: split horizontal" })
map("n", "<localleader>wo", "<C-w>o", { noremap = true, desc = "Window pane: only -- close all other panes" })

-- Searching for text
vim.keymap.set("v", "*", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('"vy', true, false, true), "v", false)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("/<c-r>v", true, false, true), "n", false)
end, { silent = true, desc = "Search with selected text" })

-- Operator-pending mode mappings for camel case motions
map("o", "X", "iW", { silent = true })
map("o", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
map("o", "igw", "<Plug>CamelCaseMotion_iw", { silent = true })
map("o", "ige", "<Plug>CamelCaseMotion_ie", { silent = true })
map("o", "igb", "<Plug>CamelCaseMotion_ib", { silent = true })
