return function(require)
	local SelectionHistory = require("SelectionHistory")

	local history

	return {
		Name = "Previous Selection";
		Description = "Go back to what you had selected before (bind this to Ctrl+K).";

		Initialize = function(plugin)
			history = SelectionHistory.get(plugin)
		end;

		ToastValue = function()
			return history:GetToastValue()
		end;

		Macro = function()
			return history:Back()
		end;
	}
end
