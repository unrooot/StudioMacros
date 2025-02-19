return {
	Name = "Move TextXAlignment Right";
	Description = "Move a TextLabel's text alignment right.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		local currentAlignment = gui.TextXAlignment

		if currentAlignment == Enum.TextXAlignment.Left then
			gui.TextXAlignment = Enum.TextXAlignment.Center
		elseif currentAlignment == Enum.TextXAlignment.Center then
			gui.TextXAlignment = Enum.TextXAlignment.Right
		end
	end;
}