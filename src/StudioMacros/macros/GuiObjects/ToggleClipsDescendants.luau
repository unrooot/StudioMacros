return {
	Name = "Toggle ClipsDescendants";
	Description = "Toggle ClipsDescendants on an object.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.ClipsDescendants = not gui.ClipsDescendants
	end;
}