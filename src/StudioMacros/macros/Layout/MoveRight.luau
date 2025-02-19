return {
	Name = "Move Right";
	Description = "Move the object's alignment to the right.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			if gui.HorizontalAlignment == Enum.HorizontalAlignment.Left then
				gui.HorizontalAlignment = Enum.HorizontalAlignment.Center
			elseif gui.HorizontalAlignment == Enum.HorizontalAlignment.Center then
				gui.HorizontalAlignment = Enum.HorizontalAlignment.Right
			end
		else
			gui.AnchorPoint = Vector2.new(math.clamp(gui.AnchorPoint.X + 0.5, 0, 1), gui.AnchorPoint.Y)
			gui.Position = UDim2.new(math.clamp(gui.Position.X.Scale + 0.5, 0, 1), 0, gui.Position.Y.Scale, 0)
		end
	end;
}