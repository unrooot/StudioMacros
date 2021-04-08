return {
	name = "Insert UIGradient";
	desc = "[StudioMacros] Inserts a UIGradient.";
	func = function(gui)
		local gradient = Instance.new("UIGradient")
		gradient.Color = Color3.fromRGB(255, 255, 255)
		gradient.Parent = gui
	end;
}