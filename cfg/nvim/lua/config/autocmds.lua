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
-- close some filetypes with <q>
-- vim.api.nvim_create_autocmd("FileType", {
-- 	group = augroup("close_with_kj"),
-- 	pattern = {
-- 		"PlenaryTestPopup",
-- 		"grug-far",
-- 		"help",
-- 		"lspinfo",
-- 		"notify",
-- 		"qf",
-- 		"spectre_panel",
-- 		"startuptime",
-- 		"tsplayground",
-- 		"neotest-output",
-- 		"checkhealth",
-- 		"neotest-summary",
-- 		"neotest-output-panel",
-- 		"dbout",
-- 		"gitsigns-blame",
-- 	},
-- 	callback = function(event)
-- 		vim.bo[event.buf].buflisted = false
-- 		vim.keymap.set("n", "q", "<cmd>close<cr>", {
-- 			buffer = event.buf,
-- 			silent = true,
-- 			desc = "Quit buffer",
-- 		})
-- 	end,
-- })
