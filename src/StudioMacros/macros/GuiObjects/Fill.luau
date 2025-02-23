return {
	Name = "Fill Size (XY)";
	Description = "Resize the object to take up 100% of the parent's size.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.Size = UDim2.fromScale(1, 1)
	end;
}