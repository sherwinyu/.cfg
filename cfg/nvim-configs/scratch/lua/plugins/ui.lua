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

				-- Increase tab bar contrast
				-- Active tab: bright background with dark text
				hl.TabLineSel = {
					fg = colors.bg_dark,
					bg = colors.blue,
					bold = true,
				}
				-- Inactive tab: subtle background with muted text
				hl.TabLine = {
					fg = colors.fg_dark,
					bg = colors.bg_highlight,
				}
				-- Tab bar fill: matches editor background
				hl.TabLineFill = {
					bg = colors.bg,
				}

				-- Make current line number more prominent
				hl.CursorLineNr = {
					fg = colors.orange,
					bold = true,
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
			local function set_theme_from_system(appearance)
				if appearance == "light" then
					vim.o.background = "light"
					vim.cmd("colorscheme tokyonight-day")
				else
					vim.o.background = "dark"
					vim.cmd("colorscheme tokyonight-moon")
				end

				-- Reload UI plugins to pick up new colors
				-- Schedule to ensure colorscheme is fully loaded
				vim.schedule(function()
					-- Reload lualine using shared config
					local ok_lualine, lualine = pcall(require, "lualine")
					if ok_lualine and _G.lualine_config then
						lualine.setup(_G.lualine_config)
					end

					-- Reconfigure incline with fresh colors
					local ok_incline, incline = pcall(require, "incline")
					if ok_incline and _G.build_incline_config then
						incline.setup(_G.build_incline_config())
					end
				end)
			end

			-- Set initial theme
			set_theme_from_system()

			-- Update theme when Neovim gains focus (event-based, no polling!)
			vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
				group = vim.api.nvim_create_augroup("auto_theme_switcher", { clear = true }),
				callback = function()
					local appearance = get_macos_appearance()
					if appearance ~= vim.o.background then
						set_theme_from_system(appearance)
					end
				end,
			})
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

			-- Shared lualine config
			local lualine_config = {
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
			}

			-- Store config globally for reuse
			_G.lualine_config = lualine_config

			require("lualine").setup(lualine_config)
		end,
	},

	-- Floating filename indicator
	{
		"b0o/incline.nvim",
		event = "BufReadPre",
		config = function()
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

			-- Store helper functions globally for reuse
			_G.incline_get_short_path = get_short_path
			_G.incline_get_diagnostics = get_diagnostics

			-- Build incline config function
			local function build_incline_config()
				-- Clear the color cache
				package.loaded["tokyonight.colors"] = nil
				local colors = require("tokyonight.colors").setup()

				return {
					window = {
						padding = 0,
						margin = { horizontal = 0, vertical = 0 },
						placement = { horizontal = "right", vertical = "bottom" },
					},
					render = function(props)
						-- Use fresh colors from cache
						local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":~:.")
						local short_path = _G.incline_get_short_path(filename)
						local modified = vim.bo[props.buf].modified and " ●" or ""

						-- Get diagnostics
						local diag = _G.incline_get_diagnostics(props.buf)
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
				}
			end

			-- Store config builder globally for reuse
			_G.build_incline_config = build_incline_config

			require("incline").setup(build_incline_config())
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
