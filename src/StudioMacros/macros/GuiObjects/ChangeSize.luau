return function(require)
	local ChangeSizeWidget = require("ChangeSizeWidget")

	return {
		Name = "Change Size";
		Description = "Set the size of a GuiObject with math (e.g. 300/x or (1/4) * 200/y).";

		Initialize = function(plugin)
			ChangeSizeWidget.get(plugin)
		end;

		Predicate = function(gui)
			return gui:IsA("GuiObject")
		end;

		Macro = function(gui, plugin)
			ChangeSizeWidget.get(plugin):Open(gui)
		end;
	}
end
