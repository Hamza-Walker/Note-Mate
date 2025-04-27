-- ~/Projects/notemate.nvim/lua/notemate/features/sync/calendar.lua
local event_bus = require("notemate.core.event_bus")

local M = {}

function M.sync_task_to_calendar(task)
	-- Path to your AppleScript
	local script_path = vim.fn.expand("~/.config/nvim/lua/notemate/features/sync/create_event.applescript")

	local cmd = string.format(
		'osascript "%s" "%s" "%s" "%s" "%s"',
		script_path,
		task.title,
		task.date .. " " .. task.start_time,
		task.date .. " " .. task.end_time,
		task.details or ""
	)

	vim.fn.jobstart(cmd, {
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				vim.notify("Task synced to calendar: " .. task.title)
				event_bus.publish("task_synced", task)
			else
				vim.notify("Failed to sync task to calendar", vim.log.levels.ERROR)
			end
		end
	})
end

return M
