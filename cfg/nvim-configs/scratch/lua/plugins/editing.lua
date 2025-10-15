-- Editing enhancement plugins
return {
	-- Tab out of brackets/quotes
	{
		"kawre/neotab.nvim",
		event = "InsertEnter",
		opts = {
			tabkey = "<c-l>",
		},
	},

	-- Case conversion
	{
		"gregorias/coerce.nvim",
		tag = "v3.0.0",
		config = true,
	},

	-- Move function parameters
	{
		"AndrewRadev/sideways.vim",
		config = function()
			vim.g.sideways_no_mappings = true
		end,
		keys = {
			{ "rh", "<cmd>SidewaysLeft<cr>", desc = "Move param left" },
			{ "rl", "<cmd>SidewaysRight<cr>", desc = "Move param right" },
		},
	},

	-- Toggle values (true/false, etc)
	{
		"AndrewRadev/switch.vim",
		init = function()
			vim.g.switch_mapping = ""
			-- Custom switch definitions (global)
			vim.g.switch_custom_definitions = {
				-- TypeScript/JavaScript specific (simple strings)
				{ "const", "let" },
				{ "import", "export" },
				{ "async", "sync" },
				{ "==", "===" },
				{ "!=", "!==" },
				{ "any", "unknown" },
				{ "type", "interface" },
				{ "map", "flatMap", "filter", "reduce" },
				{ "slice", "splice" },
				{ "find", "filter", "some", "every" },
				{ "string", "number", "boolean" },

				-- Common programming words
				{ "yes", "no" },
				{ "on", "off" },
				{ "true", "false" },
				{ "enable", "disable" },
				{ "enabled", "disabled" },
				{ "show", "hide" },
				{ "visible", "hidden" },
				{ "start", "end" },
				{ "begin", "end" },
				{ "first", "last" },
				{ "before", "after" },
				{ "up", "down" },
				{ "left", "right" },
				{ "top", "bottom" },
				{ "width", "height" },
				{ "horizontal", "vertical" },
				{ "row", "column" },
				{ "x", "y" },
				{ "min", "max" },
				{ "add", "remove" },
				{ "create", "delete" },
				{ "insert", "update", "delete" },
				{ "read", "write" },
				{ "open", "close" },
				{ "source", "target" },
				{ "from", "to" },
				{ "input", "output" },
				{ "absolute", "relative" },
				{ "&&", "||" },
				{ "and", "or" },
			}
		end,
		keys = {
			{ "r.", "<cmd>Switch<cr>", desc = "Switch" },
		},
	},

	-- Mini.ai for better text objects
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}, {}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
					d = { "%f[%d]%d+" },
					k = { "()%{().-()%}()" },
					e = {
						{
							"%u[%l%d]+%f[^%l%d]",
							"%f[%S][%l%d]+%f[^%l%d]",
							"%f[%P][%l%d]+%f[^%l%d]",
							"^[%l%d]+%f[^%l%d]",
							"%f[%w][%w%d]+[_%W]",
						},
						"^().*()$",
					},
					u = ai.gen_spec.function_call(),
					U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
				},
			}
		end,
		config = function(_, opts)
			require("mini.ai").setup(opts)
			-- Note: 'x' text object is now handled by CamelCaseMotion in motion.lua
		end,
	},

	-- Mini.surround for surround operations
	{
		"echasnovski/mini.surround",
		opts = {
			mappings = {
				add = "ys",
				delete = "ds",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "cs",
				update_n_lines = "gsn",
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
