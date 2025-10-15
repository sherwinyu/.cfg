-- UI plugins: colorscheme, statusline, notifications
return {
	-- Tokyo Night colorscheme with auto light/dark switching
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "moon", -- Default to dark mode (moon)
			on_highlights = function(hl, colors)
				hl.Visual = {
					fg = "#FFFFFF",
					bg = colors.bg_visual,
				}
				-- Style window separators for better visibility
				hl.WinSeparator = {
					fg = colors.blue0, -- Visible blue separator
					bg = colors.bg,
				}
			end,
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)

			-- Function to detect macOS appearance
			local function get_macos_appearance()
				local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
				if handle then
					local result = handle:read("*a")
					handle:close()
					return result:match("Dark") and "dark" or "light"
				end
				return "dark"
			end

			-- Function to set theme based on system appearance
			local function set_theme_from_system()
				local appearance = get_macos_appearance()
				if appearance == "light" then
					vim.o.background = "light"
					vim.cmd("colorscheme tokyonight-day")
				else
					vim.o.background = "dark"
					vim.cmd("colorscheme tokyonight-moon")
				end
			end

			-- Set initial theme
			set_theme_from_system()

			-- Update theme when Neovim gains focus (event-based, no polling!)
			-- vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
			-- 	group = vim.api.nvim_create_augroup("auto_theme_switcher", { clear = true }),
			-- 	callback = function()
			-- 		set_theme_from_system()
			-- 	end,
			-- })
		end,
	},

	-- Color highlighting
	{
		"brenoprata10/nvim-highlight-colors",
		opts = {
			render = "virtual",
		},
	},

	-- Lualine statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "folke/tokyonight.nvim" },
		config = function()
			-- Force global statusline
			vim.o.laststatus = 3

			local colors = require("tokyonight.colors").setup()
			require("lualine").setup({
				options = {
					theme = "auto",
					globalstatus = true, -- Single statusline at bottom
				},
			sections = {
				lualine_a = {
					{
						"mode",
						fmt = function(s)
							local mode_map = {
								["NORMAL"] = "N",
								["INSERT"] = "I",
								["VISUAL"] = "V",
								["V-LINE"] = "VL",
								["V-BLOCK"] = "VB",
								["COMMAND"] = "!",
								["REPLACE"] = "R",
								["TERMINAL"] = "T",
							}
							return mode_map[s] or s
						end,
					},
				},
				lualine_b = { "branch" },
				lualine_c = {
					{ "diagnostics" },
					{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
					{ "filename", path = 1 },
				},
				lualine_x = {},
				lualine_y = {
					{ "progress", separator = " ", padding = { left = 1, right = 0 } },
					{ "location", padding = { left = 0, right = 1 } },
				},
				lualine_z = {
					function()
						return " " .. os.date("%R")
					end,
				},
			},
				extensions = { "neo-tree", "lazy" },
			})
		end,
	},

	-- Floating filename indicator
	{
		"b0o/incline.nvim",
		event = "BufReadPre",
		config = function()
			local colors = require("tokyonight.colors").setup()

			-- Get last dir and filename only
			local function get_short_path(path)
				if path == "" then
					return "[No Name]"
				end

				local parts = vim.split(path, "/")
				if #parts == 1 then
					return path -- Just filename
				end

				-- Return last directory + filename
				return parts[#parts - 1] .. "/" .. parts[#parts]
			end

			-- Get diagnostic counts
			local function get_diagnostics(bufnr)
				local diagnostics = vim.diagnostic.get(bufnr)
				local counts = { errors = 0, warnings = 0, hints = 0, info = 0 }

				for _, diagnostic in ipairs(diagnostics) do
					if diagnostic.severity == vim.diagnostic.severity.ERROR then
						counts.errors = counts.errors + 1
					elseif diagnostic.severity == vim.diagnostic.severity.WARN then
						counts.warnings = counts.warnings + 1
					elseif diagnostic.severity == vim.diagnostic.severity.HINT then
						counts.hints = counts.hints + 1
					elseif diagnostic.severity == vim.diagnostic.severity.INFO then
						counts.info = counts.info + 1
					end
				end

				return counts
			end

			require("incline").setup({
				window = {
					padding = 0,
					margin = { horizontal = 0, vertical = 0 },
					placement = { horizontal = "right", vertical = "bottom" },
				},
				render = function(props)
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":~:.")
					local short_path = get_short_path(filename)
					local modified = vim.bo[props.buf].modified and " ●" or ""

					-- Get diagnostics
					local diag = get_diagnostics(props.buf)
					local diag_str = ""
					if diag.errors > 0 then
						diag_str = diag_str .. "  " .. diag.errors
					end
					if diag.warnings > 0 then
						diag_str = diag_str .. "  " .. diag.warnings
					end

					-- High contrast for focused window
					local bg = props.focused and colors.blue or colors.bg_highlight
					local fg = props.focused and colors.bg or colors.fg
					local gui = props.focused and "bold" or "none"

					return {
						{ " " .. short_path .. modified .. diag_str .. " ", guibg = bg, guifg = fg, gui = gui },
					}
				end,
			})
		end,
	},

	-- Notifications
	{
		"rcarriga/nvim-notify",
		keys = {
			{ "<leader>in", "<cmd>Telescope notify<cr>", desc = "Show notifications" },
		},
		opts = {
			timeout = 3000,
		},
	},
}
