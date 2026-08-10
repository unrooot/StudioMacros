return function(require)
	local SelectionHistory = require("SelectionHistory")

	local history

	return {
		Name = "Next Selection";
		Description = "Go forward again after stepping back through your selections (bind this to Ctrl+J).";

		Initialize = function(plugin)
			history = SelectionHistory.get(plugin)
		end;

		ToastValue = function()
			return history:GetToastValue()
		end;

		Macro = function()
			return history:Forward()
		end;
	}
end
