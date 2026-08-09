return {
	Name = "Convert Padding";
	Description = "Converts the padding on an instance with padding properties between Scale and Offset (basesd on AbsoluteSize of the parent).";

	Predicate = function(gui)
		if gui:IsA("UIPadding") then
			return true
		elseif gui:IsA("UIListLayout") or gui:IsA("UIGridLayout") then
			return true
		end

		return gui ~= nil
	end;

	Macro = function(gui)
		local parentSize = gui.Parent.AbsoluteSize

		if gui:IsA("UIPadding") then
			local paddingIsScale = gui.PaddingLeft.Scale > 0 or gui.PaddingRight.Scale > 0 or gui.PaddingTop.Scale > 0 or gui.PaddingBottom.Scale > 0

			if paddingIsScale then
				gui.PaddingLeft = UDim.new(0, gui.PaddingLeft.Scale * parentSize.X)
				gui.PaddingRight = UDim.new(0, gui.PaddingRight.Scale * parentSize.X)
				gui.PaddingTop = UDim.new(0, gui.PaddingTop.Scale * parentSize.Y)
				gui.PaddingBottom = UDim.new(0, gui.PaddingBottom.Scale * parentSize.Y)
			else
				gui.PaddingLeft = UDim.new(gui.PaddingLeft.Offset / parentSize.X, 0)
				gui.PaddingRight = UDim.new(gui.PaddingRight.Offset / parentSize.X, 0)
				gui.PaddingTop = UDim.new(gui.PaddingTop.Offset / parentSize.Y, 0)
				gui.PaddingBottom = UDim.new(gui.PaddingBottom.Offset / parentSize.Y, 0)
			end
		elseif gui:IsA("UIListLayout") then
			local paddingIsScale = gui.Padding.Scale > 0

			if paddingIsScale then
				gui.Padding = UDim.new(0, gui.Padding.Scale * parentSize.X)
			else
				gui.Padding = UDim.new(gui.Padding.Offset / parentSize.X, 0)
			end
		elseif gui:IsA("UIGridLayout") then
			local paddingIsScale = gui.CellPadding.X.Scale > 0 or gui.CellPadding.Y.Scale > 0

			if paddingIsScale then
				gui.CellPadding = UDim2.new(
					0,
					gui.CellPadding.X.Scale * parentSize.X,
					0,
					gui.CellPadding.Y.Scale * parentSize.Y
				)
			else
				gui.CellPadding = UDim2.new(
					gui.CellPadding.X.Offset / parentSize.X,
					0,
					gui.CellPadding.Y.Offset / parentSize.Y,
					0
				)
			end
		end

		return gui
	end;
}
