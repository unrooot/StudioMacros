return function(require)
	local TextServiceUtils = require("TextServiceUtils")

	return {
		Name = "Wrap X Size to Text";
		Description = "Set the width offset to fit the text's absolute size.";

		Predicate = function(gui)
			return gui:IsA("TextLabel")
				or gui:IsA("TextButton")
				or gui:IsA("TextBox")
		end;

		Macro = function(gui)
			local textSize = gui.TextSize
			if gui.TextScaled then
				textSize = math.clamp(math.floor(gui.AbsoluteSize.Y), 1, 100)
			end

			local params = Instance.new("GetTextBoundsParams")
			params.Text = gui.ContentText
			params.Size = textSize
			params.Font = gui.FontFace
			params.Width = 1e6

			local bounds = TextServiceUtils.promiseTextBounds(params):Wait()
			local currentSize = gui.Size

			gui.Size = UDim2.new(0, math.ceil(bounds.X), currentSize.Y.Scale, currentSize.Y.Offset)
		end;
	}
end
