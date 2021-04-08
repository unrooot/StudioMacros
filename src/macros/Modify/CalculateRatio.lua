return {
	name = "Calculate AspectRatio",
	desc = "[StudioMacros] Calculate an aspect ratio. (INSTRUCTIONS: Run this on a UIAspectRatioConstraint that has a UISizeConstraint next to it. Make sure MaxSize is set.)",
	func = function(gui)
		if not gui:IsA("UIAspectRatioConstraint") then
			warn("[StudioMacros] [CalculateRatio]: Selected instance must be a UIAspectRatioConstraint!")
			return
		end

		local sizeConstraint = gui.Parent:FindFirstChildOfClass("UISizeConstraint")

		if not sizeConstraint then
			warn("[StudioMacros] [CalculateRatio]: Selected instance must have a UISizeConstraint alongside it!")
			return
		end

		gui.AspectRatio = sizeConstraint.MaxSize.X / sizeConstraint.MaxSize.Y
	end
}