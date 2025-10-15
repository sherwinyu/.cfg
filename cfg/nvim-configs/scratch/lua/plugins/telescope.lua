-- Telescope configuration with custom settings
return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = function()
			local actions = require("telescope.actions")

			local function find_command()
				if 1 == vim.fn.executable("rg") then
					return { "rg", "--files", "--no-require-git", "--color", "never", "-g", "!.git" }
				elseif 1 == vim.fn.executable("fd") then
					return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
				end
			end

			return {
				defaults = {
					selection_caret = " ",
					mappings = {
						i = {
							["<c-j>"] = actions.move_selection_next,
							["<c-k>"] = actions.move_selection_previous,
							["<c-f>"] = actions.preview_scrolling_down,
							["<c-b>"] = actions.preview_scrolling_up,
							["<m-f>"] = { type = "command", "<c-o>w" },
							["<m-b>"] = { type = "command", "<c-o>b" },
							["<c-a>"] = { type = "command", "<c-o>0" },
							["<c-e>"] = { type = "command", "<c-o>$" },
							["<space><space>"] = actions.close,
							["kj"] = actions.close,
						},
						n = {
							["q"] = actions.close,
							["jk"] = actions.close,
						},
					},
				},
				pickers = {
					find_files = {
						find_command = find_command,
						hidden = true,
					},
				},
			}
		end,
		keys = {
			-- File finding moved to fzf-lua
			-- Live grep moved to fzf-lua
			{ "<leader>sr", "<cmd>Telescope resume<cr>", desc = "Telescope Resume" },
			-- Custom search commands
			{ "<leader>a", "<cmd>Ag<space>", desc = "Code search" },
			{
				"<leader>8",
				function()
					require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
				end,
				desc = "Search word under cursor",
			},
			-- File copy keymaps
			{
				"<localleader>fC",
				function()
					require("mylib.file_copy").copy_current_file()
				end,
				desc = "Copy current file path and contents",
			},
			{
				"<localleader>X",
				function()
					require("mylib.file_copy").copy_selected_files()
				end,
				desc = "Copy selected files",
			},
		},
		config = function(_, opts)
			require("telescope").setup(opts)

			-- Custom Ag command for code search
			vim.api.nvim_create_user_command("Ag", function(cmd_opts)
				require("telescope.builtin").grep_string({
					search = cmd_opts.args,
					prompt_title = "Code Search: " .. cmd_opts.args,
				})
			end, { nargs = "*" })
		end,
	},
}
