return {
	Name = "Move TextYAlignment Up";
	Description = "Move a TextLabel's text alignment up.";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui)
		local currentAlignment = gui.TextYAlignment

		if currentAlignment == Enum.TextYAlignment.Bottom then
			gui.TextYAlignment = Enum.TextYAlignment.Center
		elseif currentAlignment == Enum.TextYAlignment.Center then
			gui.TextYAlignment = Enum.TextYAlignment.Top
		end
	end;
}