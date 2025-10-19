-- Options configuration
vim.g.mapleader = " "
vim.g.maplocalleader = vim.api.nvim_replace_termcodes("<BS>", false, false, true)

local opt = vim.opt

-- General settings
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.smartindent = true
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.hlsearch = true
opt.incsearch = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.updatetime = 50
opt.autowrite = false
opt.pumblend = 0
opt.laststatus = 3 -- Global statusline (3 = one for all windows)
opt.cmdheight = 0 -- Hide command line when not in use
opt.fillchars = {
	eob = " ",
	horiz = "─",
	horizup = "┴",
	horizdown = "┬",
	vert = "│",
	vertleft = "┤",
	vertright = "├",
	verthoriz = "┼"
}
opt.list = false
opt.smartcase = true
opt.virtualedit = "block"
opt.wildmode = "longest:full,full"

-- Only show cursorline and relative numbers in active window
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	pattern = "*",
	callback = function()
		vim.wo.cursorline = true
		vim.wo.relativenumber = true
	end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
	pattern = "*",
	callback = function()
		vim.wo.cursorline = false
		vim.wo.relativenumber = false
	end,
})
