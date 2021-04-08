return {
	name = "Insert UIGradient";
	desc = "[StudioMacros] Inserts a UIAspectRatioConstraint.";
	func = function(gui)
		local gradient = Instance.new("UIAspectRatioConstraint")
		gradient.Parent = gui
	end;
}