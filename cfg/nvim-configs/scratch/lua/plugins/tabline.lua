-- Tabline configuration with tabby.nvim
return {
	{
		"nanozuki/tabby.nvim",
		event = "VimEnter",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			local theme = {
				fill = "TabLineFill",
				head = "TabLine",
				current_tab = "TabLineSel",
				tab = "TabLine",
				win = "TabLine",
				tail = "TabLine",
			}

			-- Mark tabs with multiple windows with "**" instead of tabby's default "[N+]"
			local api = require("tabby.module.api")
			local win_name = require("tabby.feature.win_name")
			require("tabby.feature.tab_name").set_default_option({
				name_fallback = function(tabid)
					local cur_win = api.get_tab_current_win(tabid)
					local name = api.is_float_win(cur_win) and "[Floating]" or win_name.get(cur_win)
					if #api.get_tab_wins(tabid) > 1 then
						name = name .. "**"
					end
					return name
				end,
			})

			require("tabby.tabline").set(function(line)
				return {
					{
						{ "  ", hl = theme.head },
					},
					line.tabs().foreach(function(tab)
						local hl = tab.is_current() and theme.current_tab or theme.tab

						-- Get custom tab name or use default
						local tab_name = vim.fn.gettabvar(tab.number(), "tabby_tab_name", "")
						if tab_name == "" then
							tab_name = tab.name()
						end

						return {
							line.sep(" ", hl, theme.fill),
							tab.is_current() and " " or " ",
							tab.number(),
							" ",
							tab_name,
							" ",
							tab.close_btn(""),
							line.sep(" ", hl, theme.fill),
							hl = hl,
							margin = " ",
						}
					end),
					line.spacer(),
					{
						line.sep("", theme.tail, theme.fill),
						{ "  ", hl = theme.tail },
					},
					hl = theme.fill,
				}
			end)
		end,
	},
}
