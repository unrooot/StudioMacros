return {
	Name = "Cycle Padding (5px, scale)";
	Description = "Cycle the UIPadding scale by 5px (5px, 10px, 15px).";

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

		local sidePadding = padding / gui.Parent.AbsoluteSize.X
		local topPadding = padding / gui.Parent.AbsoluteSize.Y

		gui.PaddingLeft = UDim.new(sidePadding, 0)
		gui.PaddingRight = UDim.new(sidePadding, 0)
		gui.PaddingTop = UDim.new(topPadding, 0)
		gui.PaddingBottom = UDim.new(topPadding, 0)
	end;
}