return {
	Name = "Cycle Padding (5px, offset)";
	Description = "Cycle the UIPadding offset by 5px (5px, 10px, 15px).";

	Predicate = function(gui)
		return gui:IsA("UIPadding")
	end;

	Macro = function(gui)
		local padding = gui.PaddingLeft.Offset

		if padding == 5 then
			padding = 10
		elseif padding == 10 then
			padding = 15
		elseif padding == 15 then
			padding = 5
		else
			if padding < 5 then
				padding = 5
			elseif padding < 10 then
				padding = 10
			elseif padding < 15 then
				padding = 15
			else
				padding = 5
			end
		end

		gui.PaddingLeft = UDim.new(0, padding)
		gui.PaddingRight = UDim.new(0, padding)
		gui.PaddingTop = UDim.new(0, padding)
		gui.PaddingBottom = UDim.new(0, padding)
	end;
}