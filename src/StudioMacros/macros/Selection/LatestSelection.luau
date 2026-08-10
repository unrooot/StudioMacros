return function(require)
	local SelectionHistory = require("SelectionHistory")

	local history

	return {
		Name = "Latest Selection";
		Description = "Jump straight back to your most recent selection after stepping back through history.";

		Initialize = function(plugin)
			history = SelectionHistory.get(plugin)
		end;

		ToastValue = function()
			return history:GetToastValue()
		end;

		Macro = function()
			return history:Latest()
		end;
	}
end
