return {
	Name = "Insert Vertical Layout";
	Description = "Insert a UIListLayout to the selected object with a vertical FillDirection, or convert a selected UIListLayout to vertical.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	ToastName = function(gui)
		return gui and gui:IsA("UIListLayout") and "Toggled FillDirection" or nil
	end;

	ToastValue = function(gui)
		return gui and gui:IsA("UIListLayout") and gui.FillDirection.Name or nil
	end;

	Macro = function(gui)
		if gui:IsA("UIListLayout") then
			gui.FillDirection = Enum.FillDirection.Vertical
			return gui
		end

		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = gui

		return list
	end;
}
