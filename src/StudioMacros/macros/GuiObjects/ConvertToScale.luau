local function getBounds(parent)
	if parent:IsA("ScreenGui") then
		return workspace.CurrentCamera.ViewportSize
	end

	return parent.AbsoluteSize
end

return {
	Name = "Convert to Scale";
	Description = "Convert the GuiObject's size, or the UIListLayout's padding, from offset to scale.";

	Predicate = function(gui)
		return gui:IsA("GuiObject") or gui:IsA("UIListLayout")
	end;

	Macro = function(gui)
		local bounds = getBounds(gui.Parent)

		if gui:IsA("UIListLayout") then
			local axisSize = if gui.FillDirection == Enum.FillDirection.Horizontal then bounds.X else bounds.Y
			local padding = gui.Padding.Scale * axisSize + gui.Padding.Offset

			gui.Padding = UDim.new(padding / axisSize, 0)
			return
		end

		local currentSize = gui.AbsoluteSize
		gui.Size = UDim2.fromScale(currentSize.X / bounds.X, currentSize.Y / bounds.Y)
	end;
}
