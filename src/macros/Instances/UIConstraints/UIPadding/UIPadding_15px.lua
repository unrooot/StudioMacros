return {
	name = "Insert UIPadding (15px)";
	desc = "[StudioMacros] Add UIPadding to an instance w/ 15px padding on all sides.";
	func = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 15)
		padding.PaddingTop = UDim.new(0, 15)
		padding.PaddingLeft = UDim.new(0, 15)
		padding.PaddingRight = UDim.new(0, 15)
		padding.Parent = gui
	end;
}