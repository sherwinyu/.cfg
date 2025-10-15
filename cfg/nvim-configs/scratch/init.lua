-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Load options first (sets leader keys before lazy loads)
require("config.options")

-- Setup lazy.nvim - imports all plugins from lua/plugins/
require("lazy").setup({
	{ import = "plugins" },
})

-- Load keymaps after lazy setup
require("config.keymaps")

-- Custom commands
vim.api.nvim_create_user_command("ToggleCopilot", function()
	if vim.g.copilot_enabled then
		vim.cmd("Copilot disable")
		vim.g.copilot_enabled = false
		print("Copilot disabled")
	else
		vim.cmd("Copilot enable")
		vim.g.copilot_enabled = true
		print("Copilot enabled")
	end
end, {})

-- Disable copilot by default
vim.g.copilot_enabled = false
pcall(function()
	vim.cmd("Copilot disable")
end)
