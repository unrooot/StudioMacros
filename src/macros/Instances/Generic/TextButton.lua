local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

return {
	name = "New TextButton";
	desc = "[StudioMacros] Create a new TextButton.";
	func = function(gui)
        local btn = Instance.new("TextButton", gui)
        btn.BackgroundColor3 = Color3.new(1, 1, 1)
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(0, 200, 0, 50)
		btn.Font = Enum.Font.SourceSans
		btn.TextSize = 14
		btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        
        pcall(function()
            btn.ZIndex = gui.ZIndex + 1
        end)
        
		Selection:Set({ btn })
	end;
}