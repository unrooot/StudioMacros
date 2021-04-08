return {
	name = "Insert UISizeConstraint";
	desc = "[StudioMacros] Inserts a UISizeConstraint.";
	func = function(gui)
		local constraint = Instance.new("UISizeConstraint")
		constraint.Parent = gui
	end;
}