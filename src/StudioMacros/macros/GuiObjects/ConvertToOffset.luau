return {
	Name = "Convert to Offset";
	Description = "Convert the GuiObject's size from scale to offset.";

	Predicate = function(gui)
		return gui:IsA("GuiObject")
	end;

	Macro = function(gui)
		local currentSize = gui.Size
		local parent = gui.Parent

		local bounds
		if parent:IsA("ScreenGui") then
			bounds = workspace.CurrentCamera.ViewportSize
		else
			bounds = parent.AbsoluteSize
		end

		gui.Size = UDim2.fromOffset(currentSize.X.Scale * bounds.X, currentSize.Y.Scale * bounds.Y)
	end;
}