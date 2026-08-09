return {
	Name = "Convert UICorner";
	Description = "Convert the CornerRadius on a UICorner between Scale and Offset.";

	Predicate = function(gui)
		return gui ~= nil and gui:IsA("UICorner")
	end;

	Macro = function(gui)
		local cornerRadius = gui.CornerRadius
		local preferredAxis = math.min(gui.Parent.AbsoluteSize.X, gui.Parent.AbsoluteSize.Y)

		if cornerRadius.Scale > 0 then
			gui.CornerRadius = UDim.new(0, cornerRadius.Scale * preferredAxis)
		else
			gui.CornerRadius = UDim.new(cornerRadius.Offset / preferredAxis, 0)
		end

		return corner
	end;
}
