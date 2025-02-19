return {
	Name = "Toggle TextTransparency";
	Description = "Switch between 0 and 1 TextTransparency on a TextLabel.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.TextTransparency = gui.TextTransparency == 0 and 1 or 0
	end;
}