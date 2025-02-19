return {
	Name = "Insert ImageLabel";
	Description = "Insert an ImageLabel to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local image = Instance.new("ImageLabel")
		image.BorderSizePixel = 0
		image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		image.Size = UDim2.fromOffset(100, 100)
		image.Parent = gui

		return image
	end;
}