return {
	Name = "Insert Text Input";
	Description = "Insert a TextBox to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local input = Instance.new("TextBox")
		input.BackgroundTransparency = 1
		input.Name = "input"
		input.ZIndex = 5
		input.Parent = gui

		return gui
	end;
}