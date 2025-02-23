return {
	Name = "Align Left";
	Description = "Align the object to the left.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			gui.HorizontalAlignment = Enum.HorizontalAlignment.Left
		else
			gui.AnchorPoint = Vector2.new(0, gui.AnchorPoint.Y)
			gui.Position = UDim2.fromScale(0, gui.Position.Y.Scale)
		end
	end;
}