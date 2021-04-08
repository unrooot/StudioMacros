return {
	name = "Insert UIPadding (empty)";
	desc = "[StudioMacros] Add UICorner to an instance.";
	func = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 0)
		padding.PaddingTop = UDim.new(0, 0)
		padding.PaddingLeft = UDim.new(0, 0)
		padding.PaddingRight = UDim.new(0, 0)
		padding.Parent = gui
	end;
}