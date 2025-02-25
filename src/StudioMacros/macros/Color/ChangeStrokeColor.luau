return {
	Name = "Change Stroke Color";
	Description = "Change the color of a UIStroke.";
	CustomResults = "Color";
	TargetProperty = "Color";

	Predicate = function(gui)
		return gui:IsA("UIStroke")
	end;

	Macro = function(gui, _, color)
		if not color then
			return
		end

		if typeof(color) == "Color3" then
			gui.Color = color
		end
	end;
}