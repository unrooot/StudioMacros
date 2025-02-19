return {
	Name = "Toggle ClipsDecendants";
	Description = "Toggle ClipsDecendants on an object.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.ClipsDescendants = not gui.ClipsDescendants
	end;
}