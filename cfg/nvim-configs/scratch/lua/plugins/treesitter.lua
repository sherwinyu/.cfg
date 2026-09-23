-- Treesitter configuration
local function find_enclosing_context()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local line = vim.api.nvim_get_current_line()
	local first_nonblank = line:find("%S")

	if not first_nonblank then
		return
	end

	local indent = first_nonblank - 1
	local parser_ok, parser = pcall(vim.treesitter.get_parser, 0)
	if not parser_ok or not parser then
		return
	end
	parser:parse()

	local ok, node = pcall(vim.treesitter.get_node, {
		bufnr = 0,
		pos = { row, indent },
		ignore_injections = false,
		include_anonymous = true,
	})

	if not ok or not node then
		return
	end

	while node do
		local start_row, start_col = node:start()
		if start_row < row and start_col < indent and node:parent() then
			return start_row + 1, start_col
		end
		node = node:parent()
	end
end

local function context_up(count)
	local jumped = false

	for _ = 1, count do
		local row, col = find_enclosing_context()
		if not row then
			break
		end

		if not jumped then
			vim.cmd([[normal! m']])
			jumped = true
		end
		vim.api.nvim_win_set_cursor(0, { row, col })
	end

	if not jumped then
		vim.notify("No enclosing Tree-sitter context found", vim.log.levels.INFO)
	end
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "tsx", "python" },
				sync_install = false,
				auto_install = true, -- Automatically install missing parsers
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TSContext" },
		init = function()
			vim.api.nvim_create_user_command("ContextUp", function(command)
				context_up(command.count)
			end, {
				count = 1,
				desc = "Jump up to an enclosing code context",
				force = true,
			})
		end,
		keys = {
			{
				"gk",
				function()
					context_up(vim.v.count1)
				end,
				desc = "Context: jump up",
			},
			{
				"<leader>ut",
				"<cmd>TSContext toggle<cr>",
				desc = "Context: toggle sticky hierarchy",
			},
		},
		opts = {
			max_lines = 3,
			multiline_threshold = 3,
			trim_scope = "outer",
			mode = "cursor",
			separator = "─",
		},
	},
}
