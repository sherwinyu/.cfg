-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local map = vim.keymap.set
local unmap = vim.keymap.del

unmap("n", "]b")
unmap("n", "[b")
unmap("n", "<space>ql")

map("i", "kj", "<Esc>", { noremap = true })
map("v", "<space><space>", "<Esc>", { noremap = true })

-- UI
map("n", "<localleader>h", "<cmd>set hlsearch!<CR>", { noremap = true, desc = "Clear search highlighting" })
-- Movement
map({ "n", "v", "o" }, "-", "^", { noremap = true })
map({ "n", "v", "o" }, "=", "$", { noremap = true })
map({ "n", "v", "o" }, "<c-a>", "^", { noremap = true })
map({ "n", "v", "o" }, "<c-e>", "$", { noremap = true })
-- Files: open / write / quit, rename, paths
map("n", "<Leader>e", ":e ", { noremap = true })

map("n", "<Leader>E", ":e <c-r>%", { noremap = true })
map("n", "<Leader>w", ":w<CR>", { noremap = true })
map("n", "<Leader>q", ":q<CR>", { noremap = true })
map("n", "<Leader>Q", ":qa", { noremap = true, desc = "Quit all" })
map("n", "<localleader>if", "", { noremap = true, desc = "Quit all" })

-- Sourcing files
map("n", "<Leader>=l", ":luafile %<CR>", { noremap = true })
map("n", "<Leader>=s", ":source %<CR>", { noremap = true })
map("v", "<Leader>=s", ":source<CR>", { noremap = true })

-- Search
map("n", "<leader>gn", ":set nohlsearch", { noremap = true, desc = "Clear search highlighting" })

-- Normal mode editing
-- Define a reusable function to run a command and return to the original cursor position
local function returnToCursorAfterCommand(cmd)
	local pos = vim.api.nvim_win_get_cursor(0) -- Save current cursor position
	-- vim.cmd('execute normal! "' .. cmd .. '"') -- Run the passed command
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", true) -- Run the passed command
	vim.api.nvim_win_set_cursor(0, pos) -- Restore the original cursor position
end
map("n", "g,", function()
	returnToCursorAfterCommand("A,<Esc>")
end, { noremap = true, desc = "Insert comma at end of line" })

map("n", "<leader>j", "i<CR><Esc>k$function()", { noremap = true, desc = "Split line" })
map("o", "x", "ie", { desc = "Word fragment" }) -- For use with cx, dx

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
map("i", "<M-b>", "<c-o>b", { noremap = true, desc = "Move back word" })
map("i", "<M-d>", "<c-o>de", { noremap = true, desc = "Delete forward word" })
map("i", "<M-d>", "<c-o>de", { noremap = true, desc = "Delete forward word" })

-- Window and tab management
map("n", "\\", "<c-w>w", { noremap = true, desc = "Next window" })
map("n", "<tab>", "<c-w>W", { noremap = true, desc = "Prev window" })
map("n", "<f1>", "1gt", { noremap = true })
map("n", "<f2>", "2gt", { noremap = true })
map("n", "<f3>", "3gt", { noremap = true })
map("n", "<f4>", "4gt", { noremap = true })
map("n", "<f5>", "5gt", { noremap = true })
map("n", "<f6>", "6gt", { noremap = true })
map("n", "<c-t>", "<cmd>tabnew<CR>", { noremap = true })

map("n", "<left>", "<C-w>h", { desc = "Go to Left Window", noremap = true })
map("n", "<down>", "<C-w>j", { desc = "Go to Lower Window", noremap = true })
map("n", "<up>", "<C-w>k", { desc = "Go to Upper Window", noremap = true })
map("n", "<right>", "<C-w>l", { desc = "Go to Right Window", noremap = true })
map("n", "<M-.>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<M-,>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<M-]>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<M-[>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

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
		-- Get the directory part of the path
		local dir = vim.fn.fnamemodify(path, ":h")

		-- If the directory doesn't exist, create it
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p") -- "p" option creates intermediate directories
		end
	end
	local old_name = vim.fn.expand("%")
	local new_name = args.args

	-- Check if a new name was provided
	if new_name == "" then
		print("Error: No new file name provided")
		return
	end

	-- Ensure the new directory exists before renaming
	ensure_directory_exists(new_name)

	-- Rename the file
	local success, err = os.rename(old_name, new_name)
	if not success then
		print("Error renaming file: " .. err)
		return
	end

	-- Update the current buffer to use the new file name
	vim.cmd("edit " .. new_name)

	-- Optionally, delete the old buffer
	vim.cmd("bdelete " .. old_name)

	print("Renamed file to: " .. new_name)
end, {
	nargs = 1, -- Require exactly one argument (the new file name)
	complete = "file", -- Enable file name completion
})
map("n", "<localleader>fr", ":RenameFile <c-r>%", { desc = "Rename file", noremap = true })

vim.keymap.set("v", "*", function()
	-- Copy curently selected text into register v
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('"vy', true, false, true), "v", false)

	-- Start search with register v
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("/<c-r>v", true, false, true), "n", false)
end, { silent = true, desc = "Search with selected text" })

-- Operator-pending mode mappings for camel case motions
map("o", "X", "iW", { silent = true })
map("o", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
map("o", "igw", "<Plug>CamelCaseMotion_iw", { silent = true })
map("o", "ige", "<Plug>CamelCaseMotion_ie", { silent = true })
map("o", "igb", "<Plug>CamelCaseMotion_ib", { silent = true })
