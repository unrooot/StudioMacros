return {
	Name = "Change Background Color";
	Description = "Change the BackgroundColor3 of a GuiObject.";
	CustomResults = "Color";
	TargetProperty = "BackgroundColor3";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui, _, color)
		if not color then
			return
		end

		if typeof(color) == "Color3" then
			gui.BackgroundColor3 = color
		end
	end;
}