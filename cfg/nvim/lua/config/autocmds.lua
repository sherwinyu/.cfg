-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	callback = function()
		local excluded_buftypes = { "nofile", "prompt" }
		local excluded_filetypes = { "notify", "fzf" }

		if
			vim.tbl_contains(excluded_buftypes, vim.bo.buftype)
			or vim.tbl_contains(excluded_filetypes, vim.bo.filetype)
		then
			return
		end

		vim.opt.relativenumber = true
	end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
	callback = function()
		local excluded_buftypes = { "nofile", "prompt" }
		local excluded_filetypes = { "notify", "fzf" }

		if
			vim.tbl_contains(excluded_buftypes, vim.bo.buftype)
			or vim.tbl_contains(excluded_filetypes, vim.bo.filetype)
		then
			return
		end

		vim.opt.relativenumber = false
	end,
})

-- Keep track of the current and previous tab
local previous_tab = nil

-- Function to switch to the most recently used tab
local function switch_to_previous_tab()
	if previous_tab then
		vim.api.nvim_set_current_tabpage(previous_tab)
	else
		print("No previous tab")
	end
end

-- Autocmd to update the previous tab before switching to a new one
vim.api.nvim_create_autocmd("TabLeave", {
	callback = function()
		previous_tab = vim.api.nvim_get_current_tabpage()
	end,
})

-- Command to switch to the most recently used tab
vim.api.nvim_create_user_command("SwitchToPreviousTab", switch_to_previous_tab, {})
