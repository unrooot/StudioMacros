return {
	Name = "Toggle TextWrapped";
	Description = "Toggle TextWrapped on a TextLabel.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.TextWrapped = not gui.TextWrapped
	end;
}