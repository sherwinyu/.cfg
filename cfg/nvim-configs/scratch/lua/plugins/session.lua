-- Automatic session management
return {
	{
		"rmagatti/auto-session",
		opts = {
			auto_session_enabled = true,
			auto_save_enabled = true,
			auto_restore_enabled = true,
			auto_session_suppress_dirs = { "~/", "~/Downloads", "/tmp" },
			auto_session_use_git_branch = false,
			bypass_session_save_file_types = { "neo-tree" },
			-- Keymaps
			session_lens = {
				load_on_setup = true,
			},
		},
		keys = {
			{ "<localleader>ss", "<cmd>AutoSession save<cr>", desc = "Save session" },
			{ "<localleader>sr", "<cmd>AutoSession restore<cr>", desc = "Restore session" },
			{ "<localleader>sd", "<cmd>AutoSession delete<cr>", desc = "Delete session" },
			{ "<localleader>sf", "<cmd>AutoSession search<cr>", desc = "Search sessions" },
		},
	},
}
