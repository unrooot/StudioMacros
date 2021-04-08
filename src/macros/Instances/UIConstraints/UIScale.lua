return {
	name = "Insert UIScale";
	desc = "[StudioMacros] Inserts a UIScale.";
	func = function(gui)
		local scale = Instance.new("UIScale")
		scale.Parent = gui
	end;
}