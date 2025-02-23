return {
	Name = "Increment Stroke Thickness";
	Description = "Increment a UIStroke's thickness.";

	Predicate = function(gui)
		return gui:IsA("UIStroke")
	end;

	Macro = function(gui)
		gui.Thickness += 1
	end;
}