-- In ~/Projects/notemate.nvim/lua/notemate/init.lua
local M = {}
function M.setup(opts)
	opts = opts or {}


	-- Rest of your setup
	require("notemate.core.event_bus")

	vim.notify("Notemate plugin initialized!")
end
