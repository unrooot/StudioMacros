return {
	Name = "Move Left";
	Description = "Move the object's alignment to the left.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			if gui.HorizontalAlignment == Enum.HorizontalAlignment.Right then
				gui.HorizontalAlignment = Enum.HorizontalAlignment.Center
			elseif gui.HorizontalAlignment == Enum.HorizontalAlignment.Center then
				gui.HorizontalAlignment = Enum.HorizontalAlignment.Left
			end
		else
			gui.AnchorPoint = Vector2.new(gui.AnchorPoint.X, math.clamp(gui.AnchorPoint.Y - 0.5, 0, 1))
			gui.Position = UDim2.new(gui.Position.X.Scale, 0, math.clamp(gui.Position.Y.Scale - 0.5, 0, 1), 0)
		end
	end;
}