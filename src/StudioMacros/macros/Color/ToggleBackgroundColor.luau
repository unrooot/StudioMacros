return {
	Name = "Toggle BackgroundColor";
	Description = "Toggle the object's BackgroundColor between black and white.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		gui.BackgroundColor3 = gui.BackgroundColor3 == Color3.new(1, 1, 1) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	end;
}