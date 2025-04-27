-- ~/Projects/notemate.nvim/lua/notemate/core/models.lua
local M = {}

M.Task = {}
M.Task.__index = M.Task

function M.Task.new(title, start_time, end_time, date, details, status)
    return setmetatable({
        title = title,
        start_time = start_time,
        end_time = end_time,
        date = date or os.date("%Y-%m-%d"),  -- Default to today
        details = details or "",
        status = status or "pending"  -- pending, completed, etc.
    }, M.Task)  -- Fixed: Removed extra comma here
end

function M.Task:to_calendar_event()
    -- Format for calendar integration
    return {
        name = self.title,
        ["begin"] = string.format("%s %s", self.date, self.start_time),  -- Fixed: begin is a reserved word
        ["end"] = string.format("%s %s", self.date, self.end_time),  -- Fixed: end is a reserved word
        description = self.details
    }
end

return M
