local M = {}

local handlers = {}

function M.subscribe(event_name, handler)
	handlers[event_name] = handlers[event_name] or {}
	table.insert(handlers[event_name], handler)
	return function()
		for i, h in ipairs(handlers[event_name]) do
			if h == handler then
				table.remove(handlers[event_name], i)
				break
			end
		end
	end
end

function M.publish(event_name, data)
	local event_handlers = handlers[event_name]
	if not event_handlers then return end

	for _, handler in ipairs(event_handlers) do
		vim.schedule(function()
			handler(data)
		end)
	end
end

return M
