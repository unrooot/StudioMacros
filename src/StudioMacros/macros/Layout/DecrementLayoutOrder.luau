return {
	Name = "Decrement Layout Order";
	Description = "Decrement the object's LayoutOrder.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.LayoutOrder -= 1
	end;
}