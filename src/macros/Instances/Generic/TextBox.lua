return {
	name = "Insert TextBox (input)";
	desc = "[StudioMacros] Adds a TextBox to an instance with preconfigured settings.";
	func = function(gui)
		local input = Instance.new("TextBox")
		input.BackgroundTransparency = 1
		input.Size = UDim2.fromScale(1, 1)
		input.Name = "input"
		input.ZIndex = 5
		input.Text = ""
		input.Parent = gui
	end;
}