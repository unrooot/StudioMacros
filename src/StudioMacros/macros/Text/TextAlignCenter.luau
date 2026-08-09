return {
	Name = "Move TextXAlignment Center";
	Description = "Move a TextLabel's text alignment center.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.TextXAlignment = Enum.TextXAlignment.Center
	end;
}
