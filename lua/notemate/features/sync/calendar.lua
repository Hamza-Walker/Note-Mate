-- ~/Projects/notemate.nvim/lua/notemate/features/sync/calendar.lua
local event_bus = require("notemate.core.event_bus")
local Path = require("plenary.path")

local M = {}

function M.get_script_path()
	-- Get the absolute path to the AppleScript
	local script_dir = Path:new(debug.getinfo(1, 'S').source:sub(2)):parent()
	return script_dir:joinpath("create_event.applescript").filename
end

function M.sync_task_to_calendar(task)
	local script_path = M.get_script_path()

	local cmd = string.format(
		'osascript "%s" "%s" "%s" "%s" "%s"',
		script_path,
		vim.fn.escape(task.title, '"\\'),
		task.date .. " " .. task.start_time,
		task.date .. " " .. task.end_time,
		vim.fn.escape(task.details or "", '"\\')
	)

	vim.fn.jobstart(cmd, {
		on_stdout = function(_, data)
			if data and #data > 0 then
				vim.notify(table.concat(data, "\n"))
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				vim.notify("Error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
			end
		end,
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

-- Get today's calendar events
function M.get_todays_events(callback)
	local script_dir = Path:new(debug.getinfo(1, 'S').source:sub(2)):parent()
	local fetch_script = script_dir:joinpath("fetch_icloud_events.applescript").filename

	vim.fn.jobstart('osascript "' .. fetch_script .. '"', {
		on_stdout = function(_, data)
			if not data or #data == 0 then
				callback({})
				return
			end

			local events = {}
			for _, line in ipairs(data) do
				if line and line ~= "" then
					local parts = vim.split(line, "\t")
					if #parts >= 3 then
						table.insert(events, {
							start_time = parts[1],
							end_time = parts[2],
							title = parts[3]
						})
					end
				end
			end

			callback(events)
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				vim.notify("Error fetching events: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
			end
			callback({})
		end
	})
end

return M

