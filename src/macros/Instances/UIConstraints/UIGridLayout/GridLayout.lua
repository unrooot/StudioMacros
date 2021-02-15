local Selection = game:GetService("Selection")

return {
	name = "Insert GridLayout";
	desc = "[StudioMacros] Insert a GridLayout w/ 100x100 cell size.";
	func = function(gui)
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = UDim2.new(0, 5, 0, 5)
		grid.CellSize = UDim2.new(0, 100, 0, 100)
		grid.Parent = gui

		Selection:Set({grid})
	end;
}