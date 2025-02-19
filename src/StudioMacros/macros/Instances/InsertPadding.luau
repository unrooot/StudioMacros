return {
	Name = "Insert Padding";
	Description = "Insert a UIPadding to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local padding = Instance.new("UIPadding")
		padding.Parent = gui

		return padding
	end;
}