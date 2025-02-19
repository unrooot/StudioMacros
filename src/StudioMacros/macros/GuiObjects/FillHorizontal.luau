return {
	Name = "Fill Horizontal (X)";
	Description = "Resize the object to take up 100% of the parent's width.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.Size = UDim2.new(1, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)
	end;
}