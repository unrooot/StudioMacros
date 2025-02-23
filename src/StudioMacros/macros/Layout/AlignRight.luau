return {
	Name = "Align Right";
	Description = "Align the object to the right.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			gui.HorizontalAlignment = Enum.HorizontalAlignment.Right
		else
			gui.AnchorPoint = Vector2.new(1, gui.AnchorPoint.Y)
			gui.Position = UDim2.fromScale(1, gui.Position.Y.Scale)
		end
	end;
}