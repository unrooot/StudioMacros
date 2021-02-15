return {
	name = "Fill Horizontal (X)";
	desc = "[StudioMacros] Resize the instance to be 100% on the X axis.";
	func = function(gui)
		gui.Size = UDim2.new(1, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)
	end;
}