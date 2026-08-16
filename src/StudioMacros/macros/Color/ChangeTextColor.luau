return {
	Name = "Change Text Color";
	Description = "Change the TextColor3 of a GuiObject.";
	CustomResults = "Color";
	TargetProperty = "TextColor3";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui, _, color, alpha)
		if typeof(color) == "Color3" then
			gui.TextColor3 = color
		end

		if type(alpha) == "number" then
			gui.TextTransparency = 1 - alpha
		end
	end;
}