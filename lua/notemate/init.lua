-- ~/Projects/notemate.nvim/lua/notemate/init.lua
local M = {}

function M.setup(opts)
	opts = opts or {}

	-- Initialize event bus
	require("notemate.core.event_bus")

	-- Any additional setup
	vim.notify("Notemate plugin initialized!")
end

return M

