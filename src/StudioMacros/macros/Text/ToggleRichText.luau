return {
	Name = "Toggle RichText";
	Description = "Toggle RichText on a TextObject.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.RichText = not gui.RichText
	end;
}