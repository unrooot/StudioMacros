return {
	Name = "Increment Layout Order";
	Description = "Increment the object's layout order.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.LayoutOrder += 1
	end;
}