local Selection = game:GetService("Selection")

return {
	name = "Insert Horizontal ListLayout";
	desc = "[StudioMacros] Insert a UIListLayout with a Horizontal FillDirection.";
	func = function(gui)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = gui

		Selection:Set({list})
	end;
}