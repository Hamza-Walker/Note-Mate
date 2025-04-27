-- ~/Projects/notemate.nvim/lua/notemate/core/db.lua
local M = {}

-- In ~/Projects/notemate.nvim/lua/notemate/core/db.lua
function M.setup()
	local cache_dir = vim.fn.stdpath("data") .. "/databases"
	vim.fn.mkdir(cache_dir, "p")

	local db_path = cache_dir .. "/notemate.db"

	-- Use protected call with proper error handling
	local ok, db_or_err = pcall(function()
		return require("sqlite").open(db_path)
	end)

	if not ok then
		vim.notify("Failed to open SQLite database: " .. tostring(db_or_err), vim.log.levels.ERROR)
		return nil
	end

	M.db = db_or_err

	-- Check if db connection is valid before using it
	if not M.db then
		vim.notify("Invalid database connection", vim.log.levels.ERROR)
		return nil
	end

	-- Create tasks table with error handling
	local success, err = pcall(function()
		M.db:execute([[
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
		vim.notify("Failed to create tasks table: " .. tostring(err), vim.log.levels.ERROR)
		return nil
	end

	return M.db
end

-- Generate unique hash for a task
function M.task_hash(task)
	return task.title .. "||" .. task.date .. "||" .. task.start_time .. "||" .. task.end_time
end

-- Updated upsert_task with proper SQL syntax
function M.upsert_task(task)
	if not M.db then
		vim.notify("Database not initialized", vim.log.levels.ERROR)
		return nil
	end

	local hash = M.task_hash(task)

	-- Use parameterized queries
	local query = [[
        INSERT INTO tasks (
            title, start_time, end_time, date, details, status, hash, synced
        ) VALUES (
            :title, :start_time, :end_time, :date, :details, :status, :hash, 0
        ) ON CONFLICT(hash) DO UPDATE SET
            status = excluded.status,
            details = excluded.details,
            synced = 0
        RETURNING id
    ]]

	local params = {
		title = task.title,
		start_time = task.start_time,
		end_time = task.end_time,
		date = task.date,
		details = task.details or "",
		status = task.status,
		hash = hash
	}

	local success, result = pcall(M.db.execute, M.db, query, params)
	if not success then
		vim.notify("Failed to upsert task: " .. tostring(result), vim.log.levels.ERROR)
		return nil
	end

	return result and result[1] and result[1].id
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

-- Fixed mark_synced with proper UPDATE syntax
function M.mark_synced(task_ids)
	if not M.db then
		vim.notify("Database not initialized", vim.log.levels.ERROR)
		return
	end

	if #task_ids == 0 then return end

	-- Batch update with IN clause
	local placeholders = table.concat({ "?" }, ",", #task_ids)
	local query = string.format([[
        UPDATE tasks
        SET synced = 1
        WHERE id IN (%s)
    ]], placeholders)

	local success, err = pcall(M.db.execute, M.db, query, task_ids)
	if not success then
		vim.notify("Failed to mark tasks as synced: " .. tostring(err), vim.log.levels.ERROR)
	end
end

return M
