local map = vim.keymap.set
return {
	{
		"bkad/CamelCaseMotion",
		config = function()
			-- Normal mode mappings
			map("n", "gw", "<Plug>CamelCaseMotion_w", { silent = true })
			map("n", "gb", "<Plug>CamelCaseMotion_b", { silent = true })
			map("n", "ge", "<Plug>CamelCaseMotion_e", { silent = true })
			map("o", "gw", "<Plug>CamelCaseMotion_w", { silent = true })
			map("o", "gb", "<Plug>CamelCaseMotion_b", { silent = true })
			map("n", "ge", "<Plug>CamelCaseMotion_e", { silent = true })

			-- Operator-pending mode mappings
			map("o", "X", "iW", { silent = true })
			map("o", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
			map("o", "igw", "<Plug>CamelCaseMotion_iw", { silent = true })
			map("o", "ige", "<Plug>CamelCaseMotion_ie", { silent = true })
			map("o", "igb", "<Plug>CamelCaseMotion_ib", { silent = true })

			-- Visual mode mappings
			map("v", "X", "iW", { silent = true })
			map("v", "x", "<Plug>CamelCaseMotion_iw", { silent = true })
		end,
	},
}
