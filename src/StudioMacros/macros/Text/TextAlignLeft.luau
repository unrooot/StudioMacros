return {
	Name = "Move TextXAlignment Left";
	Description = "Move a TextLabel's text alignment left.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		local currentAlignment = gui.TextXAlignment

		if currentAlignment == Enum.TextXAlignment.Right then
			gui.TextXAlignment = Enum.TextXAlignment.Center
		elseif currentAlignment == Enum.TextXAlignment.Center then
			gui.TextXAlignment = Enum.TextXAlignment.Left
		end
	end;
}