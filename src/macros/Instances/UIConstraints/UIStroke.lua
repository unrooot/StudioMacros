return {
	name = "Insert UIStroke";
	desc = "[StudioMacros] Inserts a UIStroke.";
	func = function(gui)
		local stroke = Instance.new("UIStroke")
		stroke.Parent = gui
	end;
}