-- There currently exists an unfortunate limitation of the Insert Objects UI in
-- Studio, which is that you can't insert to multiple instances at the same
-- time. sux.

return {
	Name = "Insert UIScale";
	Description = "Insert a UIScale into the selected object(s).";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		local scale = Instance.new("UIScale")
		scale.Parent = gui

		return scale
	end;
}
