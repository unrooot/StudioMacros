local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

return {
	name = "Create Dialog Starter";
	desc = "[StudioMacros] Create a new ScreenGui in StarterGui with a premade Frame.";
    extended = true;
	func = function()
		local gui = Instance.new("ScreenGui")
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		gui.Parent = StarterGui
        
        local frame = Instance.new("Frame", gui)
        frame.Name = 'Inner'
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.Size = UDim2.new(0, 500, 0, 300)
        frame.BorderSizePixel = 0
        
		Selection:Set({frame})
	end;
}