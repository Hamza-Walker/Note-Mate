-- ~/Projects/notemate.nvim/lua/notemate/features/sync/calendar_ics.lua
local M = {}
local event_bus = require("notemate.core.event_bus")
local db = require("notemate.core.db")
local models = require("notemate.core.models")

-- Get cache directory path
function M.get_cache_dir()
	local cache_dir = vim.fn.stdpath("cache") .. "/notemate"
	vim.fn.mkdir(cache_dir, "p")
	return cache_dir
end

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
	local ics_path = M.get_cache_dir() .. "/calendar.ics"

	local file = io.open(ics_path, "w")
	file:write(table.concat(ics_content, "\n"))
	file:close()

	return ics_path
end

-- Clean up ICS file after successful import
function M.cleanup_ics_file(ics_path)
	-- We don't delete the file, but we could mark it as processed
	-- This helps with debugging and avoids reprocessing
	local processed_path = ics_path .. ".processed"
	os.rename(ics_path, processed_path)
end

-- Open ICS file with Apple Calendar
function M.import_to_calendar(ics_path)
	vim.fn.jobstart({ "open", ics_path }, {
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("Calendar file opened in Calendar app")
				event_bus.publish("calendar_import_started", ics_path)

				-- Wait for user to complete import, then cleanup
				vim.defer_fn(function()
					M.cleanup_ics_file(ics_path)
				end, 10000) -- Wait 10 seconds before cleanup
			else
				vim.notify("Failed to open calendar file", vim.log.levels.ERROR)
			end
		end
	})
end

-- Sync only unsynced tasks to calendar
function M.sync_unsynced_tasks()
	local unsynced_db_tasks = db.get_unsynced_tasks()

	if #unsynced_db_tasks == 0 then
		vim.notify("No new tasks to sync to calendar")
		return
	end

	-- Convert DB rows to task objects
	local tasks = {}
	local task_ids = {}

	for _, task_row in ipairs(unsynced_db_tasks) do
		table.insert(tasks, models.Task.new(
			task_row.title,
			task_row.start_time,
			task_row.end_time,
			task_row.date,
			task_row.details,
			task_row.status
		))
		table.insert(task_ids, task_row.id)
	end

	vim.notify("Syncing " .. #tasks .. " new/modified tasks to calendar")
	local ics_path = M.generate_ics_file(tasks)
	M.import_to_calendar(ics_path)

	-- Mark tasks as synced once the import dialog is shown
	db.mark_synced(task_ids)
end

return M

