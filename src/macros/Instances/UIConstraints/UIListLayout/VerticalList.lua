local Selection = game:GetService("Selection")

return {
	name = "Insert Vertical ListLayout";
	desc = "[StudioMacros] Insert a UIListLayout with a Vertical FillDirection.";
	func = function(gui)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = gui

		Selection:Set({list})
	end;
}