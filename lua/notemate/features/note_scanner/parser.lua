-- ~/Projects/notemate.nvim/lua/notemate/features/note_scanner/parser.lua
local models = require("notemate.core.models")
local event_bus = require("notemate.core.event_bus")

local M = {}

function M.get_todays_date()
	return os.date("%Y-%m-%d")
end

-- More flexible pattern to match your task format
function M.parse_task_line(line)
	-- Debug output
	-- vim.notify("Checking line: " .. line)

	-- Much simpler pattern to match your actual format
	local pattern = "%*%*%* %(([%s%)]*)%) &TASK_(%d+)&:%s*%*([^%*]+)%*:%s*%[?([%d:%s%-]+)%]?"

	local status, task_num, title, time_range = line:match(pattern)

	if not status or not title or not time_range then
		return nil
	end

	-- Debug what was matched
	vim.notify("Matched task: " .. title .. " / " .. time_range)

	-- Handle time format with or without spaces
	local start_time, end_time = time_range:match("(%d+:%d+)%s*%-%s*(%d+:%d+)")
	if not start_time or not end_time then
		return nil
	end

	return models.Task.new(title, start_time, end_time, M.get_todays_date(), "",
		status:match("%s") and "pending" or "completed")
end

function M.scan_current_buffer()
	local tasks = {}
	local buffer = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

	vim.notify("Scanning " .. #lines .. " lines")

	for _, line in ipairs(lines) do
		local task = M.parse_task_line(line)
		if task then
			table.insert(tasks, task)
			event_bus.publish("task_found", task)
		end
	end

	if #tasks > 0 then
		vim.notify(string.format("Found %d tasks", #tasks))
		event_bus.publish("tasks_scanned", tasks)
	else
		vim.notify("No tasks found in current buffer")
	end

	return tasks
end

return M
