return {
	name = "Insert UIPadding (10px)";
	desc = "[StudioMacros] Add UICorner to an instance w/ 10px radius.";
	func = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 10)
		padding.PaddingTop = UDim.new(0, 10)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = gui
	end;
}