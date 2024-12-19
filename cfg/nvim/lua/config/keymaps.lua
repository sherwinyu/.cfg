-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local map = vim.keymap.set

local function unmap(mode, key)
	-- Get the current keymaps in the specified mode
	local keymaps = vim.api.nvim_get_keymap(mode)

	-- Check if the key is mapped
	local is_mapped = false
	for _, keymap in pairs(keymaps) do
		if keymap.lhs == key then
			is_mapped = true
			break
		end
	end

	if is_mapped then
		-- If mapped, unmap the key
		vim.api.nvim_del_keymap(mode, key)
		print("Unmapped key:", key)
	else
		print("[safe unmap] Key is not mapped:", key)
	end
end

unmap("n", "]b")
unmap("n", "[b")
unmap("n", "<space>ql")
unmap("n", "<space>qq")
unmap("n", "<space>qq")

map("i", "kj", "<Esc>", { noremap = true })
-- Visual
map("v", "<space><space>", "<Esc>", { noremap = true })
map("n", "<leader>v", "<c-v>", { noremap = true, desc = "Visual block" })
map("n", "<localleader>v", "<c-v>", { noremap = true, desc = "Visual block" })

-- UI
map("n", "<localleader>h", "<cmd>set hlsearch!<CR>", { noremap = true, desc = "Clear search highlighting" })
-- Movement
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

-- Sourcing files
map("n", "<localLeader>r", ":source %<CR>", { noremap = true })

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
map("n", "<leader>us", 'n"tyiw:%s/<C-r>//<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute" })
map("n", "<leader>uS", '"tyiw:s/<C-r>//<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute (line only)" })
map("v", "<leader>us", '"ty:%s/<C-r>t/<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute" })
map("v", "<leader>uS", '"ty:s/<C-r>t/<C-r>t/g<Left><Left>', { noremap = true, desc = "Substitute (line only)" })

map("n", "*", ":set hlsearch<CR>*N", { noremap = true })

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
map("i", "<M-b>", "<c-o>b", { noremap = true, desc = "Move back one word" })
map("i", "<M-BS>", "<c-w>", { noremap = true, desc = "Delete backward word" })
map("i", "<M-d>", "<c-o>de", { noremap = true, desc = "Delete forward word" })

-- Command mode;
map("c", "<M-f>", "<c-right>", { noremap = true, desc = "Move forward one word" })
map("c", "<M-b>", "<c-left>", { noremap = true, desc = "Move backward one word" })
map("c", "<c-a>", "<Home>", { noremap = true, desc = "Move to start of line" })
map("c", "<c-e>", "<End>", { noremap = true, desc = "Move to end of line" })
map("i", "<M-BS>", "<c-w>", { noremap = true, desc = "Delete backward word" })

-- Navigating in current windows
map("n", "<c-b>", "8k", { noremap = true, desc = "Scroll up" })
map("n", "<c-f>", "8j", { noremap = true, desc = "Scroll down" })
-- Window and tab management
map("n", "\\", "<c-w>w", { noremap = true, desc = "Next window" })
map("n", "<tab>", "<c-w>W", { noremap = true, desc = "Prev window" })

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
map("n", "<localleader>6", "6gt", { noremap = true })

map("n", "(", "gT", { noremap = true, desc = "Previous tab" })
map("n", ")", "gt", { noremap = true, desc = "Next tab" })
map("n", "<localleader><enter>", "<cmd>SwitchToPreviousTab<CR>", { noremap = true, desc = "Jump to alt tab" })

map("n", "<c-t>", "<cmd>tabnew<CR>", { noremap = true })

map("n", "<left>", "<C-w>h", { noremap = true, desc = "Go to Left Window" })
map("n", "<down>", "<C-w>j", { noremap = true, desc = "Go to Lower Window" })
map("n", "<up>", "<C-w>k", { noremap = true, desc = "Go to Upper Window" })
map("n", "<right>", "<C-w>l", { noremap = true, desc = "Go to Right Window" })
map("n", "<M-.>", "<cmd>resize +2<cr>", { desc = "Window Resize: increase height" })
map("n", "<M-,>", "<cmd>resize -2<cr>", { desc = "Window Resize: decrease height" })
map("n", "<M-]>", "<cmd>vertical resize -2<cr>", { desc = "Window Resize: decrease width" })
map("n", "<M-[>", "<cmd>vertical resize +2<cr>", { desc = "Window Resize: increase width" })

-- Searching for text
vim.keymap.set("v", "*", function()
	-- Copy curently selected text into register v
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('"vy', true, false, true), "v", false)

	-- Start search with register v
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("/<c-r>v", true, false, true), "n", false)
end, { silent = true, desc = "Search with selected text" })

vim.api.nvim_create_user_command("Ag", function(opts)
	require("telescope.builtin").grep_string({
		search = opts.args, -- Pre-fill the search query
		prompt_title = "Code Search: " .. opts.args, -- Custom title
	})
end, { nargs = "*" })
map("n", "<leader>a", "<cmd>Ag<space>", { noremap = true, desc = "Code search" })

local function search_word_under_cursor()
	require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
end
map("n", "<leader>8", search_word_under_cursor, { noremap = true, desc = "Search word under cursor" })

-- Operator-pending mode mappings for camel case motions
map("o", "X", "iW", { silent = true })
map("o", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
map("o", "igw", "<Plug>CamelCaseMotion_iw", { silent = true })
map("o", "ige", "<Plug>CamelCaseMotion_ie", { silent = true })
map("o", "igb", "<Plug>CamelCaseMotion_ib", { silent = true })

-- TELESCOPE STUFF
-- Function to list buffers and jump to the selected one
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function jump_to_buffer(bufnr)
	local tabs = vim.api.nvim_list_tabpages()

	for _, tab in ipairs(tabs) do
		local windows = vim.api.nvim_tabpage_list_wins(tab)

		for _, win in ipairs(windows) do
			local win_buf = vim.api.nvim_win_get_buf(win)
			if win_buf == bufnr then
				vim.api.nvim_set_current_tabpage(tab)
				vim.api.nvim_set_current_win(win)
				print("Jumped to buffer in tab " .. tab)
				return true
			end
		end
	end

	print("Buffer not found in any window.")
	return false
end

-- Telescope picker to list buffers and jump to them
local function telescope_buffer_picker()
	require("telescope.builtin").buffers({
		attach_mappings = function(_, map)
			-- actions.select_default:replace(function()
			--   local selection = action_state.get_selected_entry()
			--   actions.close(prompt_bufnr)
			--   if selection then
			--     jump_to_buffer(selection.bufnr)
			--   end
			-- end)

			map("i", "<CR>", function(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					jump_to_buffer(selection.bufnr)
				end
			end)
			return true
		end,
	})
end

-- Register a custom command in Neovim
-- vim.api.nvim_create_user_command("TelescopeJumpToBuffer", telescope_buffer_picker, {})
map("n", "<localleader>b", telescope_buffer_picker, { noremap = true, desc = "Jump to buffer" })
