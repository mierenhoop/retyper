NANO_WINDOW = arg[1] or os.exit(1)
FILENAME = arg[2] or os.exit(1)

DELAY = 100

local function get_index(t, v)
	for i, o in ipairs(t) do
		if o == v then
			return i
		end
	end

	return nil
end

local function ctags(filename, lines)
	local handle = io.popen("ctags --fields=+ne -o - "..filename)

	local patterns = {}

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

	for i, words in ipairs(patterns) do
		orders[i] = {}
		for _, word in ipairs(words) do
			if word:sub(1, 5) == "line:" then
				orders[i].start = tonumber(word:sub(6))
				orders[i].stop = orders[i].start
			elseif word:sub(1, 4) == "end:" then
				orders[i].stop = tonumber(word:sub(5))
			end
		end
		print(orders[i].start, orders[i].stop)
	end

	local unread_lines = {}

	for i = 1, #lines do
		table.insert(unread_lines, i)
	end

	for _, order in ipairs(orders) do
		for i = order.start, order.stop do
			local index = get_index(unread_lines, i)
			if index ~= nil then
				table.remove(unread_lines, index)
			else
				print("overlap", i)
			end
		end
	end

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
