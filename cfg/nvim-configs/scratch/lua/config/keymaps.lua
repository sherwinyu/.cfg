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
map("n", "<tab>", "<c-w>W", { noremap = true, desc = "Prev window" })
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

map("n", "(", "gT", { noremap = true, desc = "Tab: next" })
map("n", ")", "gt", { noremap = true, desc = "Tab: previous" })
map("n", "<localleader>(", "<cmd>tabm -1<CR>", { noremap = true, desc = "Tab: move left" })
map("n", "<localleader>)", "<cmd>tabm +1<CR>", { noremap = true, desc = "Tab: move right" })
map("n", "<c-t>", "<cmd>tabnew<CR>", { noremap = true })
map("n", "<localleader>tt", "<cmd>tabnew<CR>", { noremap = true, desc = "Tab: new" })
map("n", "<localleader>to", "<cmd>tabo<CR>", { noremap = true, desc = "Tab: Only -- Close all other tabs " })

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
