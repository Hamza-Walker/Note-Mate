-- ~/Projects/notemate.nvim/lua/notemate/features/sync/calendar_ics.lua
local M = {}
local event_bus = require("notemate.core.event_bus")
local Path = require("plenary.path")

-- Generate ICS file from tasks
function M.generate_ics_file(tasks)
	local ics_content = {
		"BEGIN:VCALENDAR",
		"VERSION:2.0",
		"PRODID:-//notemate//Calendar//EN"
	}

	for _, task in ipairs(tasks) do
		-- Format start and end times properly for ICS
		local start_date = task.date:gsub("-", "") -- Remove dashes
		local end_date = start_date
		local start_time = task.start_time:gsub(":", "") -- Remove colons
		local end_time = task.end_time:gsub(":", "")

		table.insert(ics_content, "BEGIN:VEVENT")
		table.insert(ics_content, "SUMMARY:" .. task.title)
		table.insert(ics_content, "DTSTART:" .. start_date .. "T" .. start_time .. "00")
		table.insert(ics_content, "DTEND:" .. end_date .. "T" .. end_time .. "00")
		table.insert(ics_content, "DESCRIPTION:" .. (task.details or ""))
		table.insert(ics_content, "END:VEVENT")
	end

	table.insert(ics_content, "END:VCALENDAR")

	-- Write to file
	local ics_path = vim.fn.expand("~/.cache/notemate/calendar.ics")
	local dir = vim.fn.fnamemodify(ics_path, ":h")
	vim.fn.mkdir(dir, "p")

	local file = io.open(ics_path, "w")
	file:write(table.concat(ics_content, "\n"))
	file:close()

	return ics_path
end

-- Open ICS file with Apple Calendar
function M.import_to_calendar(ics_path)
	vim.fn.jobstart({ "open", ics_path }, {
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("Calendar file opened in Calendar app")
				event_bus.publish("calendar_import_started", ics_path)
			else
				vim.notify("Failed to open calendar file", vim.log.levels.ERROR)
			end
		end
	})
end

-- Main sync function
function M.sync_tasks_to_calendar(tasks)
	vim.notify("Generating calendar file for " .. #tasks .. " tasks")
	local ics_path = M.generate_ics_file(tasks)
	M.import_to_calendar(ics_path)
end

return M
