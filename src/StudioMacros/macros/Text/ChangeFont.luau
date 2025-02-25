return {
	Name = "Change Font";
	Description = "Change the font on a text object.";
	CustomResults = "Font";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui, _, font)
		if not font then
			return
		end

		gui.FontFace = font
	end;
}