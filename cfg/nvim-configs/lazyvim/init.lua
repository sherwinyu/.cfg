require("config.lazy")

vim.api.nvim_create_user_command("TestEslint", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local cmd = vim.fn.stdpath("data") .. "/mason/bin/vscode-eslint-language-server"
	local client_id = vim.lsp.start({
		name = "eslint-test",
		cmd = { cmd, "--stdio" },
		root_dir = vim.fn.getcwd(),
	})
	if client_id then
		vim.lsp.buf_attach_client(bufnr, client_id)
		print("ESLint test started with client ID: " .. client_id)
	else
		print("Failed to start ESLint test")
	end
end, {})

vim.cmd("Copilot disable")
local copilot_enabled = false
vim.api.nvim_create_user_command("ToggleCopilot", function()
	if copilot_enabled then
		vim.cmd("Copilot disable")
		copilot_enabled = false
	else
		vim.cmd("Copilot enable")
		copilot_enabled = true
	end
end, {})
