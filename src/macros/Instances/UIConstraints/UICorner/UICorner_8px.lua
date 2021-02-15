return {
	name = "Insert UICorner (8px)";
	desc = "[StudioMacros] Add UICorner to an instance w/ 8px radius.";
	func = function(gui)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = gui
	end;
}