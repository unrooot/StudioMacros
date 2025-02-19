return {
	Name = "Toggle TextScaled";
	Description = "Toggle TextScaled on a TextLabel.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.TextScaled = not gui.TextScaled
	end;
}