return {
	"nvim-telescope/telescope.nvim", -- Ensure Telescope is loaded if using `copy_selected_files`
	config = function()
		local file_copy = require("mylib.file_copy")

		-- Set keybinding for copying the current file
		vim.keymap.set(
			"n",
			"<localleader>fC",
			file_copy.copy_current_file,
			{ noremap = true, desc = "Copy current file path and contents" }
		)

		vim.keymap.set(
			"n",
			"<localleader>X",
			file_copy.copy_selected_files,
			{ noremap = true, desc = "Copy selected files" }
		)
	end,
}
