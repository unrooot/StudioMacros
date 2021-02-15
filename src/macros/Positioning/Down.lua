return {
	name = "Down";
	desc = "[StudioMacros] Move instance down.";
	func = function(gui)
		gui.AnchorPoint = Vector2.new(gui.AnchorPoint.X, math.clamp(gui.AnchorPoint.Y + 0.5, 0, 1))
		gui.Position = UDim2.new(gui.Position.X.Scale, 0, math.clamp(gui.Position.Y.Scale + 0.5, 0, 1), 0)
	end;
}