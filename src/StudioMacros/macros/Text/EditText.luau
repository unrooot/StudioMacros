return function(require)
	local EditTextOverlay = require("EditTextOverlay")

	return {
		Name = "Edit Text";
		Description = "Edit a text object's text inline. Enter commits, Escape cancels.";

		Predicate = function(gui)
			return gui:IsA("TextLabel")
				or gui:IsA("TextButton")
				or gui:IsA("TextBox")
		end;

		Macro = function(gui, plugin)
			EditTextOverlay.get(plugin):Open(gui)
		end;
	}
end
