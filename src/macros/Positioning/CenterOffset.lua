return {
	name = "CenterWithOffset";
	desc = "[StudioMacros] Center the instance (preserves offset).";
	func = function(gui)
		gui.AnchorPoint = Vector2.new(0.5, 0.5)
		gui.Position = UDim2.new(0.5, gui.Position.X.Offset, 0.5, gui.Position.Y.Offset)
	end;
}