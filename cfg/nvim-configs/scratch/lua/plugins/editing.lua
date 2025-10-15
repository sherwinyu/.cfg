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
			{ "gh", "<cmd>SidewaysLeft<cr>", desc = "Move param left" },
			{ "gl", "<cmd>SidewaysRight<cr>", desc = "Move param right" },
		},
	},

	-- Toggle values (true/false, etc)
	{
		"AndrewRadev/switch.vim",
		init = function()
			vim.g.switch_mapping = ""
		end,
		keys = {
			{ "<leader>-", "<cmd>Switch<cr>", desc = "Switch" },
		},
	},

	-- Mini.ai for better text objects
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
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
			vim.keymap.set("o", "x", "ie", { desc = "Change word segment", noremap = false })
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
