return {
	Name = "Fill Vertical (Y)";
	Description = "Resize the object to take up 100% of the parent's height.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 1, 0)
	end;
}