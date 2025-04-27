-- ~/Projects/notemate.nvim/lua/notemate/init.lua
local M = {}

function M.setup(opts)
	opts = opts or {}

	-- Ensure database directory exists
	local db_dir = vim.fn.stdpath("data") .. "/databases"
	vim.fn.mkdir(db_dir, "p")

	-- Initialize database first, before anything else tries to use it
	local db = require("notemate.core.db")
	local db_initialized = db.setup()

	if not db_initialized then
		vim.notify("Failed to initialize database. Some features may not work.", vim.log.levels.WARN)
	else
		vim.notify("Database initialized successfully", vim.log.levels.INFO)
	end

	-- Initialize event bus after database
	require("notemate.core.event_bus")

	vim.notify("Notemate plugin initialized!")

	return M -- Return the module to allow method chaining
end

return M

