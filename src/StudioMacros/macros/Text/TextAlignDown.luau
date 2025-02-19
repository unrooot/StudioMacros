return {
	Name = "Move TextYAlignment Down";
	Description = "Move a TextLabel's text alignment down.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		local currentAlignment = gui.TextYAlignment

		if currentAlignment == Enum.TextYAlignment.Top then
			gui.TextYAlignment = Enum.TextYAlignment.Center
		elseif currentAlignment == Enum.TextYAlignment.Center then
			gui.TextYAlignment = Enum.TextYAlignment.Bottom
		end
	end;
}