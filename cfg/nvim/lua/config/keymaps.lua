-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local map = vim.keymap.set
local unmap = vim.keymap.del
vim.keymap.set("n", "a", "b", { noremap = true })
unmap("n", "]b")
unmap("n", "[b")
unmap("n", "<space>ql")

map("i", "kj", "<Esc>", { noremap = true })
map("v", "<space><space>", "<Esc>", { noremap = true })

-- Ui
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { noremap = true, desc = "Clear search highlighting" })
-- Movement
map({ "n", "v", "o" }, "-", "^", { noremap = true })
map({ "n", "v", "o" }, "=", "$", { noremap = true })
map({ "n", "v", "o" }, "<c-a>", "^", { noremap = true })
map({ "n", "v", "o" }, "<c-e>", "$", { noremap = true })
-- Opening, Writing and quitting files
map("n", "<Leader>e", ":e ", { noremap = true })

map("n", "<Leader>E", ":e <c-r>%", { noremap = true })
map("n", "<Leader>w", ":w<CR>", { noremap = true })
map("n", "<Leader>q", ":q<CR>", { noremap = true })
map("n", "<Leader>Q", ":qa", { noremap = true, desc = "Quit all" })

-- Sourcing files
map("n", "<Leader>=l", ":luafile %<CR>", { noremap = true })
map("n", "<Leader>=s", ":source %<CR>", { noremap = true })
map("v", "<Leader>=s", ":source<CR>", { noremap = true })

-- Search
map("n", "<leader>gn", ":set nohlsearch", { noremap = true, desc = "Clear search" })
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

-- Window and tab management
map("n", "\\", "<c-w>w", { noremap = true, desc = "Next window" })
map("n", "<tab>", "<c-w>W", { noremap = true, desc = "Prev window" })
map("n", "<f1>", "1gt", { noremap = true })
map("n", "<f2>", "2gt", { noremap = true })
map("n", "<f3>", "3gt", { noremap = true })
map("n", "<f4>", "4gt", { noremap = true })
map("n", "<f5>", "5gt", { noremap = true })
map("n", "<f6>", "6gt", { noremap = true })

local telescope = require("telescope.builtin")
local actions = require("telescope.actions")

-- Custom function to list only modified buffers
local function list_modified_buffers()
	telescope.buffers({
		sort_mru = true, -- Optional: Sort by most recently used
		filter_fn = function(bufnr)
			return vim.fn.getbufvar(bufnr, "&modified") == 1
		end,
	})
end

-- Create a command to call the function
vim.api.nvim_create_user_command("TelescopeModifiedBuffers", list_modified_buffers, {})
map("n", "<Leader>m", "<cmd>TelescopeModifiedBuffers<CR>", { desc = "List Modified Buffers", noremap = true })
