local map = vim.keymap.set
return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			document_highlight = { enabled = false },
		},
	},
}
