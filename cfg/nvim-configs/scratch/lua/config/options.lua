-- Options configuration
vim.g.mapleader = " "
vim.g.maplocalleader = vim.api.nvim_replace_termcodes("<BS>", false, false, true)

local opt = vim.opt

-- General settings
opt.number = true
opt.relativenumber = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.smartindent = true
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.hlsearch = false
opt.incsearch = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.updatetime = 50
opt.autowrite = false
opt.pumblend = 0
opt.laststatus = 2
opt.list = false
opt.smartcase = true
opt.virtualedit = "block"
opt.wildmode = "longest:full,full"
