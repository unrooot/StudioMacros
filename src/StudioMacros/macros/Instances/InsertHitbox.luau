return {
	Name = "Insert Hitbox";
	Description = "Insert a hitbox (invisible TextButton) to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local button = Instance.new("TextButton")
		button.Active = true
		button.BackgroundTransparency = 1
		button.Name = "button"
		button.Size = UDim2.fromScale(1, 1)
		button.Text = ""
		button.ZIndex = 5
		button.Parent = gui

		return button
	end;
}