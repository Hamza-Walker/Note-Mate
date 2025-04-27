-- ~/Projects/notemate.nvim/plugin/notemate.lua
local parser = require("notemate.features.note_scanner.parser")
local calendar = require("notemate.features.sync.calendar")
local event_bus = require("notemate.core.event_bus")

-- Command to scan the current buffer for tasks
vim.api.nvim_create_user_command("NotemateScan", function()
    parser.scan_current_buffer()
end, {})

-- Command to sync tasks with calendar
vim.api.nvim_create_user_command("NotemateSync", function()
    local tasks = parser.scan_current_buffer()
    for _, task in ipairs(tasks) do
        calendar.sync_task_to_calendar(task)
    end
end, {})

-- Listen for task_found events
event_bus.subscribe("task_found", function(task)
    vim.notify("Found task: " .. task.title)
end)

