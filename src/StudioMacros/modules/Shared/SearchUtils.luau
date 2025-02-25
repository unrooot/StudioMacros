local require = require(script.Parent.loader).load(script)

local Fzy = require("Fzy")

local SearchUtils = {}

function SearchUtils.getMatchedString(fzyConfig, targetString, searchQuery)
	if not fzyConfig or not targetString or not searchQuery then
		return
	end

	searchQuery = string.lower(searchQuery)

	local positions = Fzy.positions(fzyConfig, searchQuery, string.lower(targetString))
	if not positions or #positions == 0 then
		return targetString
	end

	local ranges = {}
	local startPos, endPos = positions[1], positions[1]

	for i = 2, #positions do
		if positions[i] == endPos + 1 then
			endPos = positions[i]

			if i == #positions then
				table.insert(ranges, { startPos, endPos })
			end
		else
			table.insert(ranges, { startPos, endPos })
			startPos = positions[i]
			endPos = positions[i]
		end
	end

	if #ranges == 0 then
		return targetString
	end

	local finalString = ""

	for index, range in ranges do
		local start = string.sub(targetString, index == 1 and 0 or ranges[index - 1][2] + 1, range[1] - 1)
		local matched = string.sub(targetString, range[1], range[2])

		finalString ..= `{start}<font color="#d0a4f7">{matched}</font>`

		if index == #ranges then
			finalString ..= string.sub(targetString, range[2] + 1, string.len(targetString))
		end
	end

	return finalString
end

function SearchUtils.stringIsRGB(str)
	if not str then
		return
	end

	local pattern = "^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$"
	local r, g, b = string.match(str, pattern)
	if r and g and b then
		r, g, b = tonumber(r), tonumber(g), tonumber(b)
		local isRGB = r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255
		return isRGB, r, g, b
	end
	return false
end

function SearchUtils.stringIsHex(str)
	if not str then
		return
	end

	str = string.lower(str)

	local pattern = "^%s*#?([0-9a-f]+)%s*$"
	local hex = string.match(str, pattern)
	if hex then
		local len = #hex
		return (len == 6 or len == 3), hex
	end
	return false
end

return SearchUtils