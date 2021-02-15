local Selection = game:GetService("Selection")

return {
	name = "New TextLabel";
	desc = "[StudioMacros] Create a new TextLabel.";
	func = function(gui)
		local label = Instance.new("TextLabel")
		label.BorderSizePixel = 0
		label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		label.Size = UDim2.fromOffset(200, 50)
		label.Font = Enum.Font.SourceSans
		label.TextSize = 14
		label.TextColor3 = Color3.fromRGB(0, 0, 0)
		label.Parent = gui

		Selection:Set({label})
	end;
}