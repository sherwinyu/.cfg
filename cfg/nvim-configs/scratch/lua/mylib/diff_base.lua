local M = {}

local bases = {}

function M.repo_root(bufnr)
	bufnr = bufnr or 0
	local path = vim.api.nvim_buf_get_name(bufnr)
	local dir = path ~= "" and vim.fn.fnamemodify(path, ":h") or vim.fn.getcwd()
	if vim.fn.isdirectory(dir) == 0 then
		dir = vim.fn.getcwd()
	end
	local result = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
	if vim.v.shell_error ~= 0 or not result[1] then
		return nil
	end
	return vim.fs.normalize(result[1])
end

function M.remember(root, base)
	if root and base then
		bases[root] = base
	end
end

function M.current()
	local root = M.repo_root()
	return root and bases[root] or nil
end

function M.apply_to_current_file()
	local base = M.current()
	if not base then
		vim.notify("Choose a diff base with <Space>dC or <Space>dc first", vim.log.levels.WARN)
		return
	end
	if not vim.b.gitsigns_status_dict then
		vim.notify("Gitsigns is not attached to this file", vim.log.levels.WARN)
		return
	end
	require("gitsigns").change_base(base, false, function(err)
		if err then
			vim.notify("Could not change hunk base: " .. err, vim.log.levels.ERROR)
		else
			vim.notify("Hunks now compare against " .. base)
		end
	end)
end

function M.reset_current_file()
	if not vim.b.gitsigns_status_dict then
		vim.notify("Gitsigns is not attached to this file", vim.log.levels.WARN)
		return
	end
	require("gitsigns").change_base(nil, false, function(err)
		if err then
			vim.notify("Could not reset hunk base: " .. err, vim.log.levels.ERROR)
		else
			vim.notify("Hunks now compare against the index")
		end
	end)
end

function M.open_current_file()
	if vim.api.nvim_buf_get_name(0) == "" then
		vim.notify("Open a file before viewing its diff", vim.log.levels.WARN)
		return
	end
	local base = M.current()
	vim.cmd("DiffviewOpen " .. (base or "") .. " -- %")
end

return M
