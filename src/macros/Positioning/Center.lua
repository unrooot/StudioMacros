return {
	name = "Center";
	desc = "[StudioMacros] Center the instance (does not preserve offset).";
	func = function(gui)
		gui.AnchorPoint = Vector2.new(0.5, 0.5)
		gui.Position = UDim2.new(0.5, 0, 0.5, 0)
	end;
}