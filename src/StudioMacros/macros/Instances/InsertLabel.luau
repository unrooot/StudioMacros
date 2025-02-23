return {
	Name = "Insert Label";
	Description = "Insert a TextLabel to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local label = Instance.new("TextLabel")
		label.BorderSizePixel = 0
		label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		label.Size = UDim2.fromOffset(200, 50)
		label.Font = Enum.Font.SourceSans
		label.TextSize = 14
		label.TextColor3 = Color3.fromRGB(0, 0, 0)
		label.Parent = gui

		return label
	end;
}