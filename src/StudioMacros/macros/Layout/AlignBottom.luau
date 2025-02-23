return {
	Name = "Align Bottom";
	Description = "Align the object to the bottom.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			gui.VerticalAlignment = Enum.VerticalAlignment.Bottom
		else
			gui.AnchorPoint = Vector2.new(gui.AnchorPoint.X, 1)
			gui.Position = UDim2.fromScale(gui.Position.X.Scale, 1)
		end
	end;
}