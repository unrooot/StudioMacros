return {
	Name = "Insert UICorner";
	Description = "Insert a UICorner to the selected object.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local corner = Instance.new("UICorner")
		corner.Parent = gui

		return corner
	end;
}