return {
	Name = "Set Text Color (White)";
	Description = "Set the text color of a TextLabel to white.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.TextColor3 = Color3.new(1, 1, 1)
	end;
}