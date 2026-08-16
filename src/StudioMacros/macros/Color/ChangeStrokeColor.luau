return {
	Name = "Change Stroke Color";
	Description = "Change the color of a UIStroke.";
	CustomResults = "Color";
	TargetProperty = "Color";

	Predicate = function(gui)
		return gui:IsA("UIStroke")
	end;

	Macro = function(gui, _, color, alpha)
		if typeof(color) == "Color3" then
			gui.Color = color
		end

		if type(alpha) == "number" then
			gui.Transparency = 1 - alpha
		end
	end;
}