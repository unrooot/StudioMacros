return {
	name = "Insert UIScale";
	desc = "[StudioMacros] Inserts a UIScale.";
	func = function(gui)
		local gradient = Instance.new("UIScale")
		gradient.Parent = gui
	end;
}