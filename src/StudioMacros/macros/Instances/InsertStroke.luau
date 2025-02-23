return {
	Name = "Insert UIStroke";
	Description = "Insert a UIStroke to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local stroke = Instance.new("UIStroke")
		stroke.Parent = gui

		return stroke
	end;
}