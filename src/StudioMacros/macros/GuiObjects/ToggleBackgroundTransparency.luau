return {
	Name = "Toggle BackgroundTransparency";
	Description = "Toggle an object's BackgroundTransparency between 0 and 1.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.BackgroundTransparency = gui.BackgroundTransparency == 0 and 1 or 0
	end;
}