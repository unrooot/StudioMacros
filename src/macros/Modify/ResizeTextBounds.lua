local TextService = game:GetService("TextService")

return {
	name = "Resize TextLabel to TextBounds.X";
	desc = "[StudioMacros] Adjusts the size of a TextLabel to conform to TextBounds.X (works if scaled!).";
	func = function(gui)
		assert(gui.ClassName == "TextLabel", "[StudioMacros] [ResizeTextBounds] Selection is not a TextLabel!")

		local bounds = TextService:GetTextSize(gui.Text, gui.TextSize, gui.Font, Vector2.new(10000, gui.AbsoluteSize.Y))
		gui.Size = UDim2.new(0, bounds.X, gui.Size.Y.Scale, gui.Size.Y.Offset)
	end;
}