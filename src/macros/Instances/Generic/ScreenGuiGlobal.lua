local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

return {
	name = "Create ScreenGui (Global ZIndexBehavior)";
	desc = "[StudioMacros] Create a new ScreenGui in StarterGui with Global ZIndexBehavior.";
    extended = true;
	func = function()
		local gui = Instance.new("ScreenGui")
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		gui.Parent = StarterGui

		Selection:Set({gui})
	end;
}