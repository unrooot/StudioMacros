return {
	Name = "Move Down";
	Description = "Move the object's alignment down.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			if gui.VerticalAlignment == Enum.VerticalAlignment.Top then
				gui.VerticalAlignment = Enum.VerticalAlignment.Center
			elseif gui.VerticalAlignment == Enum.VerticalAlignment.Center then
				gui.VerticalAlignment = Enum.VerticalAlignment.Bottom
			end
		else
			gui.AnchorPoint = Vector2.new(gui.AnchorPoint.X, math.clamp(gui.AnchorPoint.Y + 0.5, 0, 1))
			gui.Position = UDim2.new(gui.Position.X.Scale, 0, math.clamp(gui.Position.Y.Scale + 0.5, 0, 1), 0)
		end
	end;
}