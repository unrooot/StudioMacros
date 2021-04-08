return {
	name = "Insert UIPadding (5px)";
	desc = "[StudioMacros] Add UIPadding to an instance w/ 5px padding on all sides.";
	func = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 5)
		padding.PaddingTop = UDim.new(0, 5)
		padding.PaddingLeft = UDim.new(0, 5)
		padding.PaddingRight = UDim.new(0, 5)
		padding.Parent = gui
	end;
}