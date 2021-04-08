return {
	name = "Insert AspectRatio";
	desc = "[StudioMacros] Inserts a UIAspectRatioConstraint.";
	func = function(gui)
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.Parent = gui
	end;
}