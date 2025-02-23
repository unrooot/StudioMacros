return {
	Name = "Insert Horizontal Layout";
	Description = "Insert a UIListLayout to the selected object with a horizontal FillDirection.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = gui

		return list
	end;
}