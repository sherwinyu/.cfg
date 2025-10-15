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
