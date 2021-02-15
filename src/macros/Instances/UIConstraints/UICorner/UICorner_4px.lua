return {
	name = "Insert UICorner (4px)";
	desc = "[StudioMacros] Add UICorner to an instance w/ 4px radius.";
	func = function(gui)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = gui
	end;
}