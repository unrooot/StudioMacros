return {
	Name = "Decrement ZIndex";
	Description = "Decrement the object's ZIndex.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.ZIndex -= 1
	end;
}