return {
	name = "Fill Both (XY)";
	desc = "[StudioMacros] Resize the instance to be 100% on both the X and Y axis.";
	func = function(gui)
		gui.Size = UDim2.new(1, 0, 1, 0)
	end;
}