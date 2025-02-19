return {
	Name = "Insert ScrollingFrame";
	Description = "Insert a ScrollingFrame to the selected object.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		local frame = Instance.new("ScrollingFrame")
		frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.CanvasSize = UDim2.new()
		frame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		frame.ScrollBarThickness = 8
		frame.ScrollingDirection = Enum.ScrollingDirection.Y
		frame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		frame.Parent = gui

		return frame
	end;
}