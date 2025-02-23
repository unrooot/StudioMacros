return {
	Name = "Convert to Scale";
	Description = "Convert the GuiObject's size from offset to scale.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		local currentSize = gui.AbsoluteSize
		local parent = gui.Parent

		local bounds
		if parent:IsA("ScreenGui") then
			bounds = workspace.CurrentCamera.ViewportSize
		else
			bounds = parent.AbsoluteSize
		end

		gui.Size = UDim2.fromScale(currentSize.X / bounds.X, currentSize.Y / bounds.Y)
	end;
}