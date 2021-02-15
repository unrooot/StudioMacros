local Selection = game:GetService("Selection")

return {
	name = "Insert ScrollingFrame";
	desc = "[StudioMacros] Insert a ScrollingFrame with preset properties.";
	func = function(gui)
		local frame = Instance.new("ScrollingFrame")
		frame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.ScrollingDirection = Enum.ScrollingDirection.Y
		frame.ScrollBarThickness = 8
		frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.CanvasSize = UDim2.new()
		frame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		frame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		frame.Parent = gui

		Selection:Set({frame})
	end;
}