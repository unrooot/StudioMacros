return {
	Name = "Decrement Stroke Thickness";
	Description = "Decrement a UIStroke's thickness.";

	Predicate = function(gui)
		return gui:IsA("UIStroke")
	end;

	Macro = function(gui)
		if gui.Thickness - 1 < 0 then
			return
		end

		gui.Thickness -= 1
	end;
}