return {
	Name = "Insert UIGradient";
	Description = "Insert a UIGradient to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local gradient = Instance.new("UIGradient")
		gradient.Parent = gui
	end;
}