return {
	Name = "Align Top";
	Description = "Align the object to the top.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			gui.VerticalAlignment = Enum.VerticalAlignment.Top
		else
			gui.AnchorPoint = Vector2.new(gui.AnchorPoint.X, 0)
			gui.Position = UDim2.fromScale(gui.Position.X.Scale, 0)
		end
	end;
}