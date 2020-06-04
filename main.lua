NANO_WINDOW = arg[1] or os.exit(1)
FILENAME = arg[2] or os.exit(1)

DELAY = 100

local function ctags(filename)
	os.execute("ctags -f /tmp/tags "..filename)
	local file = io.open("/tmp/tags", "r");

	local patterns = {}

	for line in file:lines() do
		if line:sub(0, 1) ~= '!' then
			local words = {}
			for token in string.gmatch(line, "[^\t]+") do
				table.insert(words, token)
			end
			table.insert(patterns, words)
		end
	end

	return patterns
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
	rep = rep == 0 and "" or "--repeat "..(rep or 1).." "
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
		local start = order[1]
		local stop = order[2]

		local move = math.abs(start - position)
		local move_key = (position < start and "Down" or "Up")
		print(move, move_key)

		type_key(move_key, nil, move)

		for i = start, stop do
			type_line(lines[i])
			type_key("Down")
		end
		position = stop + 1

	end
end


local lines = get_lines(FILENAME)
local patterns = ctags(FILENAME)

local orders = {
	{ 8, 12 },
	{ 1, 3 },
	{ 4, 6 },
}

type_all(orders, lines)
