return {
	Name = "Format Container";
	Description = "Take a GuiObject with an offset size and convert it to scale with UIAspectRatio/UISizeConstraints.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		local size = gui.AbsoluteSize

		local sizeConstraint = Instance.new("UISizeConstraint")
		sizeConstraint.MaxSize = size
		sizeConstraint.Parent = gui

		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.AspectRatio = size.X / size.Y
		aspectRatio.Parent = gui

		gui.Size = UDim2.fromScale(1, 1)
	end;
}