local Selection = game:GetService("Selection")

return {
	name = "New ImageLabel";
	desc = "[StudioMacros] Create a new ImageLabel.";
	func = function(gui)
		local image = Instance.new("ImageLabel")
		image.BorderSizePixel = 0
		image.Size = UDim2.new(0, 100, 0, 100)
		image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		image.BorderSizePixel = 0
		image.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		image.Parent = gui

		Selection:Set({image})
	end;
}