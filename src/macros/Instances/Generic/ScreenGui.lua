local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

return {
	name = "Create ScreenGui";
	desc = "[StudioMacros] Create a new ScreenGui in StarterGui.";
	func = function()
		local gui = Instance.new("ScreenGui")
		gui.ResetOnSpawn = false
		gui.Parent = StarterGui

		Selection:Set({gui})
	end;
}