-- fzf-lua configuration
return {
	{
		"ibhagwan/fzf-lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"kkharji/sqlite.lua", -- For frecency tracking
		},
		keys = {
			-- Main menu
			{ "<leader>fz", "<cmd>FzfLua<cr>", desc = "FzfLua menu" },
			-- Command palette (like VS Code)
			{ "<leader>p", "<cmd>FzfLua commands<cr>", desc = "Command Palette" },
			{ "<leader>s;", "<cmd>FzfLua commands<cr>", desc = "Command Palette" },
			{
				"<leader><leader>",
				"<cmd>FzfLua oldfiles cwd_only=true include_current_session=true<cr>",
				desc = "Recent files",
			},
			-- Files & search
			{ "<leader>t", "<cmd>FzfLua files<cr>", desc = "All files" },
			{ "<leader>T", "<cmd>FzfLua oldfiles cwd_only=true include_current_session=true<cr>", desc = "Recent files" },
			{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "All files" },
			{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find buffers" },
			{ "<leader>fr", "<cmd>FzfLua oldfiles cwd_only=true include_current_session=true<cr>", desc = "Find recent files" },
			{ "<leader>fF", "<cmd>FzfLua oldfiles cwd_only=true include_current_session=true<cr>", desc = "Recent files" },
			{ "<leader>fR", "<cmd>FzfLua resume<cr>", desc = "Resume last search" },
			{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
			{ "<leader>/", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
			{
				"<leader>./",
				function()
					local word = vim.fn.expand("<cword>")
					require("fzf-lua").live_grep({ search = word })
				end,
				desc = "Live grep with word under cursor pre-filled",
			},
			-- Help & keymaps
			{ "<leader>sh", "<cmd>FzfLua help_tags<cr>", desc = "Help" },
			{ "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
			{ "<leader>:", "<cmd>FzfLua command_history<cr>", desc = "Command history" },
			-- Git
			{ "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git commits" },
			{ "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git status" },
		},
		opts = {
			winopts = {
				height = 0.85,
				width = 0.80,
				preview = {
					layout = "vertical",
					vertical = "down:45%",
				},
			},
			files = {
				-- Show recent files at the top by default
				fd_opts = "--color=never --type f --hidden --follow --exclude .git",
				-- Combine recent files with all files
				cmd = "rg --files --hidden --follow -g '!.git'",
				actions = {
					["ctrl-g"] = function(_, opts)
						-- Toggle to all files
						require("fzf-lua").files(opts)
					end,
				},
			},
			oldfiles = {
				cwd_only = true,
				include_current_session = true,
				actions = {
					["ctrl-g"] = function(_, opts)
						-- Toggle to all files
						require("fzf-lua").files(opts)
					end,
					["ctrl-b"] = function(_, opts)
						-- Toggle to buffers
						require("fzf-lua").buffers(opts)
					end,
				},
			},
			buffers = {
				actions = {
					["ctrl-g"] = function(_, opts)
						-- Toggle to all files
						require("fzf-lua").files(opts)
					end,
					["ctrl-o"] = function(_, opts)
						-- Toggle to oldfiles
						require("fzf-lua").oldfiles(opts)
					end,
				},
			},
		},
	},
}
