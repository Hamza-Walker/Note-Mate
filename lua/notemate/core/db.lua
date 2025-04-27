-- ~/Projects/notemate.nvim/lua/notemate/core/db.lua
local M = {}

function M.setup()
	-- Ensure sqlite module is loaded correctly
	local ok, sqlite = pcall(require, "sqlite")
	if not ok then
		vim.notify("Failed to load sqlite module. Make sure it's installed.", vim.log.levels.ERROR)
		return nil
	end

	-- Create cache directory with better error handling
	local cache_dir = vim.fn.stdpath("cache") .. "/notemate"
	local mkdir_result = vim.fn.mkdir(cache_dir, "p")
	if mkdir_result ~= 1 and not vim.fn.isdirectory(cache_dir) then
		vim.notify("Failed to create cache directory: " .. cache_dir, vim.log.levels.ERROR)
		return nil
	end

	-- Open database with better error handling
	local db_path = cache_dir .. "/tasks.db"
	local db, err = sqlite:open(db_path)

	if not db then
		vim.notify("Failed to open database: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return nil
	end

	-- Store reference in module
	M.db = db

	-- Create tasks table with better error handling
	local success, err = pcall(function()
		M.db:exec([[
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY,
                title TEXT NOT NULL,
                start_time TEXT NOT NULL,
                end_time TEXT NOT NULL,
                date TEXT NOT NULL,
                details TEXT,
                status TEXT,
                synced INTEGER DEFAULT 0,
                hash TEXT UNIQUE
            )
        ]])
	end)

	if not success then
		vim.notify("Failed to create tasks table: " .. (err or "unknown error"), vim.log.levels.ERROR)
		return nil
	end

	vim.notify("Database initialized successfully", vim.log.levels.INFO)
	return db
end

-- Generate unique hash for a task
function M.task_hash(task)
	return task.title .. "||" .. task.date .. "||" .. task.start_time .. "||" .. task.end_time
end

-- Store or update task in database
function M.upsert_task(task)
	if not M.db then
		vim.notify("Database not initialized", vim.log.levels.ERROR)
		return nil
	end

	local hash = M.task_hash(task)

	-- Check if task already exists with error handling
	local success, existing = pcall(function()
		return M.db:select("tasks", { where = { hash = hash } })
	end)

	if not success then
		vim.notify("Failed to query database: " .. tostring(existing), vim.log.levels.ERROR)
		return nil
	end

	if existing and #existing > 0 then
		-- Update existing task
		local success, err = pcall(function()
			M.db:update("tasks", {
				status = task.status,
				details = task.details or "",
				synced = 0 -- Mark for re-sync
			}, { hash = hash })
		end)

		if not success then
			vim.notify("Failed to update task: " .. tostring(err), vim.log.levels.ERROR)
			return nil
		end

		return existing[1].id
	else
		-- Insert new task
		local success, id = pcall(function()
			return M.db:insert("tasks", {
				title = task.title,
				start_time = task.start_time,
				end_time = task.end_time,
				date = task.date,
				details = task.details or "",
				status = task.status,
				hash = hash,
				synced = 0
			})
		end)

		if not success then
			vim.notify("Failed to insert task: " .. tostring(id), vim.log.levels.ERROR)
			return nil
		end

		return id
	end
end

-- Get all unsynced tasks
function M.get_unsynced_tasks()
	if not M.db then
		vim.notify("Database not initialized", vim.log.levels.ERROR)
		return {}
	end

	local success, tasks = pcall(function()
		return M.db:select("tasks", { where = { synced = 0 } })
	end)

	if not success then
		vim.notify("Failed to query unsynced tasks: " .. tostring(tasks), vim.log.levels.ERROR)
		return {}
	end

	return tasks or {}
end

-- Mark tasks as synced
function M.mark_synced(task_ids)
	if not M.db then
		vim.notify("Database not initialized", vim.log.levels.ERROR)
		return
	end

	for _, id in ipairs(task_ids) do
		local success, err = pcall(function()
			M.db:update("tasks", { synced = 1 }, { id = id })
		end)

		if not success then
			vim.notify("Failed to mark task " .. tostring(id) .. " as synced: " .. tostring(err),
				vim.log.levels.ERROR)
		end
	end
end

return M

