local M = {}

local enabled = true
local saved_winbars = {}
local rendered_winbars = {}

local function parsed_language(bufnr)
	local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok_parser or not parser then
		return nil
	end
	if not pcall(parser.parse, parser) then
		return nil
	end
	return parser:lang()
end

local classes = {
	class_declaration = true,
	class_definition = true,
	class_expression = true,
	abstract_class_declaration = true,
	interface_declaration = true,
}

local functions = {
	function_declaration = true,
	generator_function_declaration = true,
	function_definition = true,
	function_expression = true,
	generator_function = true,
	method_definition = true,
}

local name_types = {
	identifier = true,
	property_identifier = true,
	private_property_identifier = true,
	type_identifier = true,
	field_identifier = true,
	dotted_name = true,
	dot_index_expression = true,
	method_index_expression = true,
}

local function name_text(node, bufnr)
	if not node or not name_types[node:type()] then
		return nil
	end
	local name = vim.trim(vim.treesitter.get_node_text(node, bufnr):gsub("%s+", " "))
	return name ~= "" and name or nil
end

local function assigned_name(node, bufnr)
	local parent = node:parent()
	while parent and (
		parent:type() == "parenthesized_expression"
		or parent:type() == "as_expression"
		or parent:type() == "satisfies_expression"
		or parent:type() == "type_assertion"
	) do
		node, parent = parent, parent:parent()
	end
	if not parent then
		return nil
	end
	local kind = parent:type()
	if kind == "variable_declarator" and parent:field("value")[1] == node then
		return name_text(parent:field("name")[1], bufnr)
	end
	if kind == "pair" and parent:field("value")[1] == node then
		return name_text(parent:field("key")[1], bufnr)
	end
	if kind == "expression_list" and parent:parent() and parent:parent():type() == "assignment_statement" then
		local assignment = parent:parent()
		local variables = assignment:named_child(0)
		if variables and variables:type() == "variable_list" then
			for i = 0, parent:named_child_count() - 1 do
				if parent:named_child(i) == node then
					return name_text(variables:named_child(i), bufnr)
				end
			end
		end
	end
	return nil
end

local function scope_label(node, bufnr)
	local kind = node:type()
	if classes[kind] or functions[kind] then
		local label = name_text(node:field("name")[1], bufnr)
		if not label then
			label = assigned_name(node, bufnr)
		end
		return label, classes[kind] and "class" or "function"
	end
	if kind == "arrow_function" then
		return assigned_name(node, bufnr), "function"
	end
	return nil
end

local function fit(text, width)
	if width <= 0 then
		return ""
	end
	if vim.fn.strdisplaywidth(text) <= width then
		return text
	end
	if width == 1 then
		return "…"
	end
	local chars = vim.fn.strchars(text)
	while chars > 0 and vim.fn.strdisplaywidth(vim.fn.strcharpart(text, 0, chars)) > width - 1 do
		chars = chars - 1
	end
	return vim.fn.strcharpart(text, 0, chars) .. "…"
end

local function breadcrumbs(winid)
	local bufnr = vim.api.nvim_win_get_buf(winid)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local parts = { path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]" }
	local width = math.max(1, vim.api.nvim_win_get_width(winid) - 2)
	if not parsed_language(bufnr) then
		return fit(parts[1], width)
	end

	local cursor = vim.api.nvim_win_get_cursor(winid)
	local ok_node, node = pcall(vim.treesitter.get_node, {
		bufnr = bufnr,
		pos = { cursor[1] - 1, cursor[2] },
		ignore_injections = true,
	})
	if not ok_node then
		return fit(parts[1], width)
	end

	local scopes = {}
	while node do
		local label, kind = scope_label(node, bufnr)
		if label then
			table.insert(scopes, { label = fit(label, 48), kind = kind })
		end
		node = node:parent()
	end

	local selected = {}
	for i = 1, math.min(3, #scopes) do
		table.insert(selected, scopes[i])
	end
	for i = #selected + 1, #scopes do
		if scopes[i].kind == "class" then
			if #selected == 3 then
				selected[3] = scopes[i]
			else
				table.insert(selected, scopes[i])
			end
			break
		end
	end
	for i = #selected, 1, -1 do
		table.insert(parts, selected[i].label)
	end

	while #parts > 2 and vim.fn.strdisplaywidth(table.concat(parts, " › ")) > width do
		table.remove(parts, #parts - 1)
	end
	if vim.fn.strdisplaywidth(table.concat(parts, " › ")) > width then
		if #parts == 1 or width < 5 then
			return fit(parts[1], width)
		end
		local separator_width = vim.fn.strdisplaywidth(" › ")
		parts[1] = fit(parts[1], math.max(1, width - separator_width - vim.fn.strdisplaywidth(parts[2])))
		parts[2] = fit(parts[2], width - separator_width - vim.fn.strdisplaywidth(parts[1]))
	end
	return table.concat(parts, " › ")
end

local function restore(winid)
	if saved_winbars[winid] ~= nil and vim.api.nvim_win_is_valid(winid) then
		vim.wo[winid].winbar = saved_winbars[winid]
	end
	saved_winbars[winid] = nil
	rendered_winbars[winid] = nil
end

local function update(winid)
	if not vim.api.nvim_win_is_valid(winid) then
		return
	end
	local bufnr = vim.api.nvim_win_get_buf(winid)
	if not enabled or vim.api.nvim_win_get_config(winid).relative ~= "" or vim.bo[bufnr].buftype ~= "" then
		restore(winid)
		return
	end
	if saved_winbars[winid] == nil then
		local current = vim.wo[winid].winbar
		saved_winbars[winid] = current
		for other, rendered in pairs(rendered_winbars) do
			if current == rendered and saved_winbars[other] ~= nil then
				saved_winbars[winid] = saved_winbars[other]
				break
			end
		end
	end
	local bar = (" " .. breadcrumbs(winid)):gsub("%%", "%%%%")
	if vim.wo[winid].winbar ~= bar then
		vim.wo[winid].winbar = bar
	end
	rendered_winbars[winid] = bar
end

local function update_all()
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		update(winid)
	end
end

function M.toggle()
	enabled = not enabled
	local sticky = require("treesitter-context")
	if enabled then
		sticky.disable()
	else
		sticky.enable()
	end
	update_all()
	vim.notify(enabled and "Always-show breadcrumbs on" or "Always-show breadcrumbs off")
end

function M.enabled()
	return enabled
end

function M.setup()
	local group = vim.api.nvim_create_augroup("scratch_context_breadcrumbs", { clear = true })
	vim.api.nvim_create_autocmd({
		"BufEnter", "CursorMoved", "CursorMovedI", "FileType", "TextChanged", "WinEnter", "WinScrolled", "WinResized",
	}, {
		group = group,
		callback = function()
			update(vim.api.nvim_get_current_win())
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(args)
			saved_winbars[tonumber(args.match)] = nil
			rendered_winbars[tonumber(args.match)] = nil
		end,
	})
	vim.api.nvim_create_user_command("ContextAlwaysToggle", M.toggle, {
		desc = "Toggle always-show Tree-sitter breadcrumbs",
	})
	update_all()
end

return M
