return {
	name = "Insert UISizeConstraint";
	desc = "[StudioMacros] Inserts a UISizeConstraint.";
	func = function(gui)
		local gradient = Instance.new("UISizeConstraint")
		gradient.Parent = gui
	end;
}