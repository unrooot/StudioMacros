return {
	Name = "Center";
	Description = "Center the object to the parent.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			gui.VerticalAlignment = Enum.VerticalAlignment.Center
			gui.HorizontalAlignment = Enum.VerticalAlignment.Center
		else
			gui.AnchorPoint = Vector2.new(0.5, 0.5)
			gui.Position = UDim2.fromScale(0.5, 0.5)
		end
	end;
}