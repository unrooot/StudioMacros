local Selection = game:GetService("Selection")

return {
	name = "New Frame";
	desc = "[StudioMacros] Create a new Frame.";
	func = function(gui)
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = UDim2.new(0, 100, 0, 100)
		frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		frame.Parent = gui

		Selection:Set({frame})
	end;
}