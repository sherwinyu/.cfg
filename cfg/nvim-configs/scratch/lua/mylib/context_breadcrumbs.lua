local M = {}

local enabled = true
local saved_winbars = {}
local rendered_winbars = {}

local function context_query(bufnr)
	local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok_parser or not parser then
		return nil
	end
	if not pcall(parser.parse, parser) then
		return nil
	end
	local ok_query, query = pcall(vim.treesitter.query.get, parser:lang(), "context")
	return ok_query and query or nil
end

local function is_context(node, query, bufnr)
	local row = node:start()
	for _, match in query:iter_matches(node, bufnr, row, row + 1, { max_start_depth = 0 }) do
		for id, captures in pairs(match) do
			if query.captures[id] == "context" then
				local captured = type(captures) == "table" and captures[#captures] or captures
				if captured == node then
					return true
				end
			end
		end
	end
	return false
end

local function breadcrumbs(winid)
	local bufnr = vim.api.nvim_win_get_buf(winid)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local parts = { path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]" }
	local query = context_query(bufnr)
	if not query then
		return parts[1]
	end

	local cursor = vim.api.nvim_win_get_cursor(winid)
	local ok_node, node = pcall(vim.treesitter.get_node, {
		bufnr = bufnr,
		pos = { cursor[1] - 1, cursor[2] },
		ignore_injections = true,
	})
	if not ok_node then
		return parts[1]
	end

	local labels = {}
	local seen_rows = {}
	while node do
		local row = node:start()
		if not seen_rows[row] and is_context(node, query, bufnr) then
			local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
			local label = vim.trim(line:gsub("%s+", " "))
			label = label:gsub("^local function ", "")
			label = label:gsub("^async function ", "")
			label = label:gsub("^function ", "")
			label = label:gsub("^def ", "")
			label = label:gsub("^class ", "")
			label = label:gsub(" then$", "")
			if label ~= "" then
				table.insert(labels, 1, vim.fn.strcharpart(label, 0, 48))
				seen_rows[row] = true
			end
		end
		node = node:parent()
	end

	while #labels > 3 do
		table.remove(labels, 1)
	end
	vim.list_extend(parts, labels)
	local width = math.max(20, vim.api.nvim_win_get_width(winid) - 4)
	while #parts > 2 and vim.fn.strdisplaywidth(table.concat(parts, " › ")) > width do
		table.remove(parts, 2)
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
