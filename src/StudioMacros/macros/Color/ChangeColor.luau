return function(require)
	local ColorPropertyUtils = require("ColorPropertyUtils")

	return {
		Name = "Change Color";
		Description = "Change whichever color property fits the instance (text, background, image, stroke, part).";
		CustomResults = "Color";

		TargetProperty = ColorPropertyUtils.getProperty;

		Predicate = function(instance)
			return ColorPropertyUtils.getProperty(instance) ~= nil
		end;

		ToastName = function(instance)
			return `Change {ColorPropertyUtils.getLabel(ColorPropertyUtils.getProperty(instance))}`
		end;

		Macro = function(instance, _, color)
			if typeof(color) ~= "Color3" then
				return
			end

			ColorPropertyUtils.setColor(instance, color)
		end;
	}
end
