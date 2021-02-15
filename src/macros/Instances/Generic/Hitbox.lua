local Selection = game:GetService("Selection")

return {
	name = "Insert Hitbox";
	desc = "[StudioMacros] Create a hitbox (invisible textbutton).";
	func = function(gui)
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.Text = ""
		button.ZIndex = 5
		button.Name = "button"
		button.Size = UDim2.fromScale(1, 1)
		button.Parent = gui

		Selection:Set({button})
	end;
}