return function(require)
	local TextServiceUtils = require("TextServiceUtils")

	return {
		Name = "Wrap Y Size to Text";
		Description = "Set the height offset to fit the text's absolute size.";

		Predicate = function(gui)
			return gui:IsA("TextLabel")
				or gui:IsA("TextButton")
				or gui:IsA("TextBox")
		end;

		Macro = function(gui)
			local currentSize = gui.Size

			if gui.TextScaled then
				gui.Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, 0, math.round(gui.AbsoluteSize.Y))
				return
			end

			local params = Instance.new("GetTextBoundsParams")
			params.Text = gui.ContentText
			params.Size = gui.TextSize
			params.Font = gui.FontFace

			if gui.TextWrapped then
				params.Width = math.max(gui.AbsoluteSize.X, 1)
			else
				params.Width = 1e6
			end

			local bounds = TextServiceUtils.promiseTextBounds(params):Wait()

			gui.Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, 0, math.ceil(bounds.Y * gui.LineHeight))
		end;
	}
end
