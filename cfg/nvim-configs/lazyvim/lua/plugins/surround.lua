local map = vim.keymap.set

return {
	{
		-- Tab out plugin
		"kawre/neotab.nvim",
		event = "InsertEnter",
		opts = {
			tabkey = "<c-l>",
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = function()
			-- PERF: we don't need this lualine require madness 🤷
			local lualine_require = require("lualine_require")
			lualine_require.require = require

			local icons = LazyVim.config.icons

			local mode_map = {
				["NORMAL"] = "N",
				["O-PENDING"] = "N?",
				["INSERT"] = "I",
				["VISUAL"] = "V",
				["V-BLOCK"] = "VB",
				["V-LINE"] = "VL",
				["V-REPLACE"] = "VR",
				["REPLACE"] = "R",
				["COMMAND"] = "!",
				["SHELL"] = "SH",
				["TERMINAL"] = "T",
				["EX"] = "X",
				["S-BLOCK"] = "SB",
				["S-LINE"] = "SL",
				["SELECT"] = "S",
				["CONFIRM"] = "Y?",
				["MORE"] = "M",
			}
			vim.o.laststatus = vim.g.lualine_laststatus

			local opts = {
				options = {
					theme = "auto",
					globalstatus = vim.o.laststatus == 3,
					disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
				},
				sections = {
					lualine_a = {
						{
							"mode",
							fmt = function(s)
								return mode_map[s] or s
							end,
						},
					},
					lualine_b = { "branch" },

					lualine_c = {
						LazyVim.lualine.root_dir(),
						{
							"diagnostics",
							symbols = {
								error = icons.diagnostics.Error,
								warn = icons.diagnostics.Warn,
								info = icons.diagnostics.Info,
								-- hint = icons.diagnostics.Hint,
							},
						},
						{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
						{ LazyVim.lualine.pretty_path() },
					},
					-- lualine_x = {
					--        -- stylua: ignore
					--        {
					--          function() return require("noice").api.status.command.get() end,
					--          cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
					--          color = function() return LazyVim.ui.fg("Statement") end,
					--        },
					--        -- stylua: ignore
					--        {
					--          function() return require("noice").api.status.mode.get() end,
					--          cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
					--          color = function() return LazyVim.ui.fg("Constant") end,
					--        },
					--        -- stylua: ignore
					--        {
					--          function() return "  " .. require("dap").status() end,
					--          cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
					--          color = function() return LazyVim.ui.fg("Debug") end,
					--        },
					-- 	{
					-- 		"diff",
					-- 		symbols = {
					-- 			added = icons.git.added,
					-- 			modified = icons.git.modified,
					-- 			removed = icons.git.removed,
					-- 		},
					-- 		source = function()
					-- 			local gitsigns = vim.b.gitsigns_status_dict
					-- 			if gitsigns then
					-- 				return {
					-- 					added = gitsigns.added,
					-- 					modified = gitsigns.changed,
					-- 					removed = gitsigns.removed,
					-- 				}
					-- 			end
					-- 		end,
					-- 	},
					-- },
					lualine_y = {
						{ "progress", separator = " ", padding = { left = 1, right = 0 } },
						{ "location", padding = { left = 0, right = 1 } },
					},
					lualine_z = {
						function()
							return " " .. os.date("%R")
						end,
					},
				},
				extensions = { "neo-tree", "lazy" },
			}

			-- do not add trouble symbols if aerial is enabled
			-- And allow it to be overriden for some buffer types (see autocmds)
			if vim.g.trouble_lualine and LazyVim.has("trouble.nvim") then
				local trouble = require("trouble")
				local symbols = trouble.statusline({
					mode = "symbols",
					groups = {},
					title = false,
					filter = { range = true },
					format = "{kind_icon}{symbol.name:Normal}",
					hl_group = "lualine_c_normal",
				})
				table.insert(opts.sections.lualine_c, {
					symbols and symbols.get,
					cond = function()
						return vim.b.trouble_lualine ~= false and symbols.has()
					end,
				})
			end

			return opts
		end,
	},
	{
		"brenoprata10/nvim-highlight-colors",
		opts = {
			render = "virtual",
		},
		-- color = '#FFFFFF'
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
		config = function()
			require("tokyonight").setup({
				style = "moon", -- Use your preferred style: night, storm, or day
				on_highlights = function(hl, colors)
					-- Increase the contrast of the visual selection
					hl.Visual = {
						fg = "#FFFFFF",
						bg = colors.bg_visual,
					}
				end,
				on_colors = function()
					-- colors.bg_statusline = colors.bg_statusline:lighten(0.1)
				end,
			})
			vim.cmd("colorscheme tokyonight-moon")
		end,
	},
	{
		"rcarriga/nvim-notify",
		keys = {
			{ "<leader>in", "<cmd>Telescope notify<cr>", desc = "Show notifications" },
		},
	},
	{
		"hrsh7th/nvim-cmp",
		opts = function()
			vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
			local cmp = require("cmp")
			local defaults = require("cmp.config.default")()
			local auto_select = true
			return {
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				auto_brackets = {}, -- configure any filetype to auto add brackets
				completion = {
					completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
				},
				-- completion = cmp.config.window.bordered(),
				preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = LazyVim.cmp.confirm({ select = auto_select }),
					["<C-y>"] = LazyVim.cmp.confirm({ select = true }),
					["<S-CR>"] = LazyVim.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
					["<C-CR>"] = function(fallback)
						cmp.abort()
						fallback()
					end,
				}),
				sources = cmp.config.sources({
					{ name = "copilot", group_index = 2 },
					{ name = "nvim_lsp" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),

				formatting = {
					format = function(entry, item)
						local icons = LazyVim.config.icons.kinds
						if icons[item.kind] then
							item.kind = icons[item.kind] .. item.kind
						end

						local widths = {
							abbr = vim.g.cmp_widths and vim.g.cmp_widths.abbr or 40,
							menu = vim.g.cmp_widths and vim.g.cmp_widths.menu or 30,
						}

						for key, width in pairs(widths) do
							if item[key] and vim.fn.strdisplaywidth(item[key]) > width then
								item[key] = vim.fn.strcharpart(item[key], 0, width - 1) .. "…"
							end
						end

						return item
					end,
				},
				experimental = {
					ghost_text = {
						hl_group = "CmpGhostText",
					},
				},
				sorting = defaults.sorting,
			}
		end,
	},
	{
		"folke/noice.nvim",
		opts = {
			presets = {
				lsp_doc_border = true,
			},
		},
	},
	{
		"folke/todo-comments.nvim",
		enabled = false,
	},
	{
		"gregorias/coerce.nvim",
		tag = "v3.0.0",
		config = true,
	},
	{
		"AndrewRadev/sideways.vim",
		config = function()
			vim.g.sideways_no_mappings = true
		end,
		keys = {
			{ "gh", "<cmd>SidewaysLeft<cr>", desc = "Move param left" },
			{ "gl", "<cmd>SidewaysRight<cr>", desc = "Move param right" },
		},
	},
	{
		"AndrewRadev/switch.vim",
		init = function()
			vim.g.switch_mapping = ""
		end,
		-- config = function()
		-- 	vim.g.switch_mapping = "<leader>-"
		-- end,
		keys = {
			{ "<leader>-", "<cmd>Switch<cr>", desc = "Switch" },
		},
	},
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			{ "<leader>bp", false, "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
			{ "<leader>bP", false, "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
			{ "<leader>bo", false, "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
			{ "<leader>br", false, "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
			{ "<leader>bl", false, "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
			{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[b", false, "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "]b", false, "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[B", false, "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
			{ "]B", false, "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
		},
		opts = {
			options = {
				mode = "tabs",
				diagnostics = "nvim_lsp",
				always_show_bufferline = false,
				diagnostics_indicator = function(_, _, diag)
					local icons = LazyVim.config.icons.diagnostics
					local ret = (diag.error and icons.Error .. diag.error .. " " or "")
						.. (diag.warning and icons.Warn .. diag.warning or "")
					return vim.trim(ret)
				end,
				separator_style = "slant",
				show_duplicate_prefix = false,
				offsets = {
					{
						filetype = "neo-tree",
						text = "Neo-tree",
						highlight = "Directory",
						text_align = "left",
					},
				},
				---@param opts bufferline.IconFetcherOpts
				get_element_icon = function(opts)
					return LazyVim.config.icons.ft[opts.filetype]
				end,
			},
		},
		config = function(_, opts)
			require("bufferline").setup(opts)
			-- Fix bufferline when restoring a session
			vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
				callback = function()
					vim.schedule(function()
						pcall(nvim_bufferline)
					end)
				end,
			})
		end,
	},
	{
		"folke/flash.nvim",
		enabled = false,
	},
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		-- keys = {
		-- 	{ "cx", "cie", desc = "Change word fragment", noremap = false },
		-- 	{ "dx", "die", desc = "Delete word fragment", noremap = false },
		-- },
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({ -- code block
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
					d = { "%f[%d]%d+" }, -- digits
					k = { "()%{().-()%}()" },
					e = { -- Word with case
						{
							"%u[%l%d]+%f[^%l%d]",
							"%f[%S][%l%d]+%f[^%l%d]",
							"%f[%P][%l%d]+%f[^%l%d]",
							"^[%l%d]+%f[^%l%d]",
							"%f[%w][%w%d]+[_%W]", -- Handle CAPS_CASE
						},

						"^().*()$",
					},
					i = LazyVim.mini.ai_indent, -- indent
					g = LazyVim.mini.ai_buffer, -- buffer
					u = ai.gen_spec.function_call(), -- u for "Usage"
					U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
				},
			}
		end,
		config = function(_, opts)
			require("mini.ai").setup(opts)
			LazyVim.on_load("which-key.nvim", function()
				vim.schedule(function()
					LazyVim.mini.ai_whichkey(opts)
				end)
			end)

			map("o", "x", "ie", { desc = "Change word segment", noremap = false })
		end,
	},

	{
		"echasnovski/mini.surround",
		opts = {
			mappings = {
				add = "ys", -- Add surrounding in Normal and Visual modes
				delete = "ds", -- Delete surrounding.
				find = "gsf", -- Find surrounding (to the right)
				find_left = "gsF", -- Find surrounding (to the left)
				highlight = "gsh", -- Highlight surrounding
				replace = "cs", -- Replace surrounding
				update_n_lines = "gsn", -- Update `n_lines`
			},
			custom_surroundings = {
				["B"] = {
					output = { left = "{", right = "}" },
					input = { "%{().-()%}" },
				},
				["k"] = {
					output = { left = "{", right = "}" },
					input = { "%{().-()%}" },
				},
				["r"] = {
					output = { left = "[", right = "]" },
					input = { "%[().-()%]" },
				},
				["a"] = {
					output = { left = "<", right = ">" },
					input = { "%<().-()%>" },
				},
			},
		},
	},
}
