return {
	Name = "Create ScreenGui";
	Description = "Create a new ScreenGui in StarterGui.";

	Macro = function()
		local screenGui = Instance.new("ScreenGui")
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = game:GetService("StarterGui")

		return screenGui
	end;
}