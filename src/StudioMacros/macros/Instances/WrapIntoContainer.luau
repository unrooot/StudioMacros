local function isDescendantOfAny(instance, others)
	for _, other in others do
		if other ~= instance and instance:IsDescendantOf(other) then
			return true
		end
	end

	return false
end

return {
	Name = "Wrap into Container";
	Description = "Wrap the selected GuiObjects in a transparent container frame.";
	RunOnSelection = true;

	Predicate = function(instance)
		return (instance:IsA("GuiObject") or instance:IsA("UIComponent")) and instance.Parent ~= nil
	end;

	Macro = function(instances)
		local first = instances[1]

		local container = Instance.new("Frame")
		container.Name = "container"
		container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0

		if #instances == 1 and first:IsA("GuiObject") then
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

			for _, instance in instances do
				if container:IsDescendantOf(instance) or isDescendantOfAny(instance, instances) then
					continue
				end

				instance.Parent = container
			end
		end

		return container
	end;
}
