return function(value: number): string
	local rounded = math.round(value * 1000) / 1000

	if rounded == math.round(rounded) then
		return string.format("%.0f", rounded)
	end

	return (string.gsub(string.format("%.3f", rounded), "0+$", ""))
end
