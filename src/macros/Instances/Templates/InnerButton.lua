local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

return {
	name = "Create Inner Button";
	desc = "[StudioMacros] Create a new Button encapsulated in a Frame.";
	func = function(gui)
		local frame = Instance.new("Frame", gui)
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(0, 200, 0, 50)
        
        pcall(function()
            frame.ZIndex = gui.ZIndex + 1
        end)
        
        local btn = Instance.new("TextButton", frame)
        btn.Name = 'Input'
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.Position = UDim2.new(0.5, 0, 0.5, 0)
        btn.BackgroundColor3 = Color3.new(1, 1, 1)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BorderSizePixel = 0
		btn.Font = Enum.Font.SourceSans
		btn.TextSize = 14
		btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.ZIndex = frame.ZIndex
        
		Selection:Set({ frame })
	end;
}