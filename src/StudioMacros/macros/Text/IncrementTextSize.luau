return {
	Name = "Increment Text Size";
	Description = "Increment the object's TextSize.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		gui.TextSize += 1
	end;
}