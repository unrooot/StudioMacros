return function(require)
	local NumberInputWidget = require("NumberInputWidget")
	local Rx = require("Rx")
	local RxInstanceUtils = require("RxInstanceUtils")

	local function getGui(target: Instance): GuiObject?
		if target:IsA("GuiObject") then
			return target
		end

		local parent = target.Parent

		return parent and parent:IsA("GuiObject") and parent or nil
	end

	local config = {
		Id = "AspectRatio";
		Title = "change aspect ratio";
		Caption = "ratio";
		Prompt = "type an aspect ratio (16:9, 1.5, x/y)...";
		RecordingName = "Change Aspect Ratio";

		Predicate = function(instance)
			return instance:IsA("GuiObject") or instance:IsA("UIAspectRatioConstraint")
		end;

		ObserveValue = function(target)
			if target:IsA("UIAspectRatioConstraint") then
				return RxInstanceUtils.observeProperty(target, "AspectRatio")
			end

			return RxInstanceUtils.observeProperty(target, "AbsoluteSize"):Pipe({
				Rx.map(function(absoluteSize)
					return absoluteSize.Y > 0 and absoluteSize.X / absoluteSize.Y or nil
				end)
			})
		end;

		GetVariables = function(target)
			local gui = getGui(target)
			local absoluteSize = gui and gui.AbsoluteSize or Vector2.zero

			local variables = {
				x = absoluteSize.X;
				y = absoluteSize.Y;
			}

			if target:IsA("UIAspectRatioConstraint") then
				variables.ratio = target.AspectRatio
			elseif absoluteSize.Y > 0 then
				variables.ratio = absoluteSize.X / absoluteSize.Y
			end

			return variables
		end;

		Sanitize = function(text)
			return (string.gsub(text, ":", "/"))
		end;

		Validate = function(value)
			return value > 0
		end;

		Apply = function(target, value)
			local constraint = target

			if not target:IsA("UIAspectRatioConstraint") then
				constraint = target:FindFirstChildOfClass("UIAspectRatioConstraint")

				if not constraint then
					constraint = Instance.new("UIAspectRatioConstraint")
					constraint.Parent = target
				end
			end

			constraint.AspectRatio = value
		end;
	}

	return {
		Name = "Change Aspect Ratio";
		Description = "Set the aspect ratio of a GuiObject with math, adding a UIAspectRatioConstraint if it needs one (e.g. 16:9 or x/y).";

		CustomResults = "Number";
		NumberInput = config;

		Initialize = function(plugin)
			NumberInputWidget.get(plugin, config)
		end;

		OpenWindow = function(plugin)
			NumberInputWidget.get(plugin, config):Open()
		end;

		Predicate = config.Predicate;

		Macro = function(gui, _plugin, value)
			config.Apply(gui, value)
		end;
	}
end
