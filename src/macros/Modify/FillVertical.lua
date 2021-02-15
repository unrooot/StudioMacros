return {
	name = "Fill Vertical (Y)";
	desc = "[StudioMacros] Resize the instance to be 100% on the Y axis.";
	func = function(gui)
		gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 1, 0)
	end;
}