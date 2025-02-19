return {
	Name = "Insert Grid Layout";
	Description = "Insert a UIGridLayout to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = UDim2.new(0, 5, 0, 5)
		grid.CellSize = UDim2.new(0, 100, 0, 100)
		grid.Parent = gui

		return grid
	end;
}