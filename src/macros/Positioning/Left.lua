return {
	name = "Left";
	desc = "[StudioMacros] Move instance to the left.";
	func = function(gui)
		gui.AnchorPoint = Vector2.new(math.clamp(gui.AnchorPoint.X - 0.5, 0, 1), gui.AnchorPoint.Y)
		gui.Position = UDim2.new(math.clamp(gui.Position.X.Scale - 0.5, 0, 1), 0, gui.Position.Y.Scale, 0)
	end;
}