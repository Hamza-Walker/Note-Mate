local models = require("notemate.core.models")
local event_bus = require("notemate.core.event_bus")

local M = {}

function M.get_todays_date()
	return os.date("%Y-%m-%d")
end

-- Extract task from a line like "*** ( ) &TASK_2&: *Moodle Support*: [15:00-17:00]"
function M.parse_task_line(line)
	-- match the task line
	local status, title, time_range = line:match("%%%*%*%* %((.-)%) &TASK_%d+&: %*(.-)%*: %[(.-)%]")

	if not status or not line or not time_range then
		return nil
	end

	-- parse time_range
	local start_time, end_time = time_range:match("(%d+:%d+)%-(%d+:%d+)")
	if not start_time or not end_time then
		return nil
	end

	return models.Task.new(title, start_time, end_time, M.get_todays_date(), "",
		status == " " and "pending" or "completed")
end

function M.scan_current_buffer()
	local tasks = {}
	local buffer = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)

	for _, line in ipairs(lines) do
		local task = M.parse_task_line(line)
		if task then
			table.insert(tasks, task)
			-- Publish task found event
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
