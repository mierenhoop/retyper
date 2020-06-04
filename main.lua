-- The window which has nano or any other text editor open
NANO_WINDOW = arg[1] or os.exit(1)

-- Name of the file which will be retyped
FILENAME = arg[2] or os.exit(1)

-- The default delay between keypressed (in milliseconds)
DELAY = 100

-- Search for the index of a value in a table
local function get_index(t, v)
	for i, o in ipairs(t) do
		if o == v then
			return i
		end
	end

	return nil
end

-- Calls the cmake executable and turns it into orders
-- Orders contain the start and stop lines
local function ctags(filename, lines)
	local handle = io.popen("ctags --fields=+ne -o - "..filename)

	local patterns = {}

	-- Parse the output of ctags into a table
	for line in handle:lines() do
		if line:sub(0, 1) ~= '!' then
			local words = {}
			for token in string.gmatch(line, "[^\t]+") do
				table.insert(words, token)
			end
			table.insert(patterns, words)
		end
	end

	local orders = {}

	for _, words in ipairs(patterns) do
		local order = {}
		for _, word in ipairs(words) do
			if word:sub(1, 5) == "line:" then
				order.start = tonumber(word:sub(6))
				order.stop = order.start
			elseif word:sub(1, 4) == "end:" then
				order.stop = tonumber(word:sub(5))
			end
		end
		for i, prev in ipairs(orders) do
			-- If the order is nested within a previous order,
			-- split it into two seperate orders
			if prev.start < order.start and order.stop < prev.stop then
				local new_order = {}
				new_order.start = prev.start
				new_order.stop = order.start - 1
				prev.start = order.stop + 1
				table.insert(orders, i, new_order)
			end
			if order.start < prev.start and prev.stop < order.stop then
				local new_order = {}
				new_order.start = order.start
				new_order.stop = prev.start - 1
				order.start = prev.stop + 1
				table.insert(orders, new_order)
			end
		end
		table.insert(orders, order)
	end

	-- Unread_lines is a table that contains all the line numbers that
	-- aren't covered by the tags (like comments and #include)
	local unread_lines = {}

	-- Initialize with all the line numbers
	for i = 1, #lines do
		table.insert(unread_lines, i)
	end

	-- Only keep the line numbers which aren't covered
	-- (so removing those inside the bounds of an "order")
	for _, order in ipairs(orders) do
		for i = order.start, order.stop do
			local index = get_index(unread_lines, i)
			if index ~= nil then
				table.remove(unread_lines, index)
			else
				error("overlap "..tostring(i))
			end
		end
	end

	-- Prepend the lines to the table (this should be changed later)
	for i = #unread_lines, 1, -1 do
		table.insert(orders, 1, { start = unread_lines[i], stop = unread_lines[i] })
	end

	-- for _, words in ipairs(patterns) do
	-- 	if words[1] == "main" then
	-- 		for i, line in ipairs(lines) do
	-- 			local pat = words[3]:sub(2, words[3]:len()-3)
	-- 			-- TODO: Make this better
	-- 			pat = pat:gsub("[%(%)%{]", ".")
	-- 			print(string.find(line, pat), pat, line)
	-- 		end
	-- 		break
	-- 	end
	-- end

	return orders
end

local function get_lines(filename)
	local file = io.open(filename, "r")
	local lines = {}

	for line in file:lines() do
		table.insert(lines, line)
	end

	return lines
end

local function type_key(key, delay, rep)
	delay = "--delay "..(delay or DELAY).." "
	if rep == 0 then return end
	rep = "--repeat "..(rep or 1).." "
	os.execute("xdotool key "..delay..rep.." --window "..NANO_WINDOW.." "..key)
end

local function type_line(text, delay)
	delay = "--delay "..(delay or DELAY).." "
	os.execute("xdotool type "..delay.."--window "..NANO_WINDOW.." \""..text.."\" ")
end

local function type_all(orders, lines)
	type_key("Down", 0, 3000)
	type_key("BackSpace", 0, 3000)
	-- Make space for all lines
	type_key("Return", 0, #lines)

	type_key("Up", 0, #lines)

	local position = 1

	for _, order in ipairs(orders) do
		local move = math.abs(order.start - position)
		local move_key = (position < order.start and "Down" or "Up")

		type_key(move_key, nil, move)

		for i = order.start, order.stop do
			type_line(lines[i])
			type_key("Down")
		end
		position = order.stop + 1

	end
end


local lines = get_lines(FILENAME)
local orders = ctags(FILENAME, lines)

type_all(orders, lines)
