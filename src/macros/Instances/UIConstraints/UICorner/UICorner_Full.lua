return {
	name = "Insert UICorner (100%)";
	desc = "[StudioMacros] Add UICorner to an instance w/ 100% radius.";
	func = function(gui)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = gui
	end;
}