return {
	Name = "Insert Frame";
	Description = "Insert a Frame to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = UDim2.new(0, 100, 0, 100)
		frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		frame.Parent = gui

		return frame
	end;
}