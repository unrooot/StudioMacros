return {
	Name = "Wrap into Container";
	Description = "Wrap the selected GuiObjects in a transparent container frame.";
	RunOnSelection = true;

	Predicate = function(gui)
		return gui:IsA("GuiObject") and gui.Parent ~= nil
	end;

	Macro = function(guis)
		local first = guis[1]

		local container = Instance.new("Frame")
		container.Name = "container"
		container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0

		if #guis == 1 then
			container.AnchorPoint = first.AnchorPoint
			container.Position = first.Position
			container.Size = first.Size
			container.LayoutOrder = first.LayoutOrder
			container.Parent = first.Parent

			first.Parent = container
			first.AnchorPoint = Vector2.zero
			first.Position = UDim2.new()
			first.Size = UDim2.fromScale(1, 1)
		else
			container.Size = UDim2.fromScale(1, 1)
			container.Parent = first.Parent

			for _, gui in guis do
				if container:IsDescendantOf(gui) then
					continue
				end

				gui.Parent = container
			end
		end

		return container
	end;
}
