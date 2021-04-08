return {
	name = "Insert UIGradient";
	desc = "[StudioMacros] Inserts a UIGradient.";
	func = function(gui)
		local gradient = Instance.new("UIGradient")
		gradient.Parent = gui
	end;
}