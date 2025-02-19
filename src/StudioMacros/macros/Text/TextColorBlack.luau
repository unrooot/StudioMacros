return {
	Name = "Set Text Color (Black)";
	Description = "Set the text color of a TextLabel to black.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.TextColor3 = Color3.new(0, 0, 0)
	end;
}