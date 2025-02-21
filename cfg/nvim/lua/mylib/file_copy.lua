local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local conf = require("telescope.config").values

-- Function to read a file and return a formatted string with filename and contents
local function copy_file_with_name(filepath)
	local rel_path = vim.fn.fnamemodify(filepath, ":.")
	local file = io.open(rel_path, "r")
	if not file then
		return nil -- Return nil if the file can't be opened
	end
	local content = file:read("*all")
	file:close()
	return rel_path .. ":\n" .. content
end

-- Function to select multiple files and copy their formatted contents to the clipboard
local function copy_selected_files()
	pickers
		.new({}, {
			prompt_title = "Select files",
			finder = finders.new_oneshot_job({ "fd", "--type", "f" }, {}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				local function copy_files()
					local picker = action_state.get_current_picker(prompt_bufnr)
					local multi_selection = picker:get_multi_selection()

					-- Check if multiple files were selected
					local has_multi_selection = (next(multi_selection) ~= nil)

					local result = {}

					if has_multi_selection then
						-- Apply function to each selected file
						action_utils.map_selections(prompt_bufnr, function(selection)
							local filepath = selection[1] -- Extract path
							local formatted_content = copy_file_with_name(filepath)
							if formatted_content then
								table.insert(result, formatted_content)
							end
						end)
					else
						-- Fallback to single selection
						local selected_entry = action_state.get_selected_entry()
						if selected_entry then
							local formatted_content = copy_file_with_name(selected_entry[1])
							if formatted_content then
								table.insert(result, formatted_content)
							end
						end
					end

					-- Copy result to clipboard if there is content
					if #result > 0 then
						local final_str = table.concat(result, "\n\n")
						vim.fn.setreg("+", final_str)
						print("Copied selected file contents to clipboard!")
					else
						print("No valid files selected.")
					end

					actions.close(prompt_bufnr)
				end

				map("i", "<CR>", copy_files)
				map("n", "<CR>", copy_files)

				return true
			end,
		})
		:find()
end

local function copy_current_file()
	local filepath = vim.api.nvim_buf_get_name(0) -- Get the current buffer's file path
	filepath = vim.fn.fnamemodify(filepath, ":.")
	if filepath == "" then
		print("No file associated with the current buffer.")
		return
	end

	local content = copy_file_with_name(filepath)
	if content then
		vim.fn.setreg("+", content) -- Copy to system clipboard
		print("Copied current file contents to clipboard!")
	else
		print("Failed to read file.")
	end
end

-- Keybinding to trigger file selection and copying

-- Expose functions for modular use
return {
	copy_file_with_name = copy_file_with_name,
	copy_current_file = copy_current_file,
	copy_selected_files = copy_selected_files,
}
