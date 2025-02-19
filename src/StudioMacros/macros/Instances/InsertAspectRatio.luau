return {
	Name = "Insert UIAspectRatioConstraint";
	Description = "Insert a UIAspectRatioConstraint to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.Parent = gui
	end;
}