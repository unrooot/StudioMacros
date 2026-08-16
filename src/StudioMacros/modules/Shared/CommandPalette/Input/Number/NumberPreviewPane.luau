local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ValueObject = require("ValueObject")

local ACCENT_COLOR = Color3.fromRGB(197, 156, 242)
local ERROR_COLOR = Color3.fromRGB(180, 84, 86)

--[=[
	The strip pinned above the results while a "Number" macro is active. The
	palette's own input stays the text field; this only echoes what the typed
	expression evaluates to, so there is never a second textbox competing for
	focus.

	@class NumberPreviewPane
]=]
local NumberPreviewPane = setmetatable({}, BasicPane)
NumberPreviewPane.ClassName = "NumberPreviewPane"
NumberPreviewPane.CustomResultType = "Number"
NumberPreviewPane.Height = 52
NumberPreviewPane.Pinned = true
NumberPreviewPane.__index = NumberPreviewPane

function NumberPreviewPane.new()
	local self = setmetatable(BasicPane.new(), NumberPreviewPane)

	self._caption = self._maid:Add(ValueObject.new(""))
	self._isEmpty = self._maid:Add(ValueObject.new(true))
	self._isValid = self._maid:Add(ValueObject.new(true))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._preview = self._maid:Add(ValueObject.new(""))
	self._targetParent = self._maid:Add(ValueObject.new(nil))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function NumberPreviewPane:SetCaption(caption: string)
	self._caption.Value = caption or ""
end

--[=[
	@param preview string -- the formatted result, or why it couldn't be read
	@param isValid boolean
	@param isEmpty boolean -- nothing typed yet, so dim rather than flag it
]=]
function NumberPreviewPane:SetPreview(preview: string, isValid: boolean, isEmpty: boolean)
	self._isEmpty.Value = isEmpty
	self._isValid.Value = isValid
	self._preview.Value = preview
end

function NumberPreviewPane:SetTargetParent(targetParent)
	self._targetParent.Value = targetParent
end

function NumberPreviewPane:GetYPosition()
	local frame = self._frame
	return frame and math.round(frame.AbsolutePosition.Y) or 0
end

function NumberPreviewPane:Render(props)
	local percentVisible = Blend.Spring(self._percentVisibleTarget:Observe(), 40, 0.8)

	local percentInvalid = Blend.Spring(Blend.Computed(self._isValid, self._isEmpty, function(isValid, isEmpty)
		return (not isValid and not isEmpty) and 1 or 0
	end), 35, 0.9)

	local emphasisColor = Blend.Computed(percentInvalid, function(invalid)
		return ACCENT_COLOR:Lerp(ERROR_COLOR, invalid)
	end)

	return Blend.New "Frame" {
		Name = "NumberPreviewPane";
		BackgroundTransparency = 1;
		LayoutOrder = -9e9;
		Parent = self._targetParent;
		Size = UDim2.new(1, 0, 0, self.Height);

		Visible = Blend.Computed(props.CustomResult, props.Enabled, function(customResult, isEnabled)
			return customResult and isEnabled or false
		end);

		[Blend.Instance] = function(frame)
			self._frame = frame
		end;

		Blend.New "Frame" {
			Name = "wrapper";
			BackgroundColor3 = Color3.fromRGB(15, 15, 15);
			Size = UDim2.new(1, 0, 1, -10);

			BackgroundTransparency = Blend.Computed(props.Transparency, percentVisible, function(parentTransparency, percent)
				return math.clamp(parentTransparency + (1 - percent), 0, 1)
			end);

			Position = Blend.Computed(percentVisible, function(percent)
				return UDim2.new(0, 0, 0, (1 - percent) * 6)
			end);

			Blend.New "UICorner" {
				CornerRadius = UDim.new(0, 5);
			};

			Blend.New "UIStroke" {
				Color = emphasisColor;

				Transparency = Blend.Computed(props.Transparency, percentVisible, function(parentTransparency, percent)
					return math.clamp(parentTransparency + (1 - percent), 0, 1)
				end);
			};

			Blend.New "UIPadding" {
				PaddingLeft = UDim.new(0, 12);
				PaddingRight = UDim.new(0, 12);
			};

			Blend.New "TextLabel" {
				Name = "caption";
				AnchorPoint = Vector2.new(0, 0.5);
				BackgroundTransparency = 1;
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
				Position = UDim2.fromScale(0, 0.5);
				Size = UDim2.fromScale(0.3, 1);
				Text = self._caption;
				TextColor3 = emphasisColor;
				TextSize = 14;
				TextXAlignment = Enum.TextXAlignment.Left;

				TextTransparency = Blend.Computed(props.Transparency, percentVisible, function(parentTransparency, percent)
					return math.clamp(parentTransparency + (1 - percent), 0, 1)
				end);
			};

			Blend.New "TextLabel" {
				Name = "preview";
				AnchorPoint = Vector2.new(1, 0.5);
				BackgroundTransparency = 1;
				FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
				Position = UDim2.fromScale(1, 0.5);
				Size = UDim2.fromScale(0.7, 1);
				Text = self._preview;
				TextTruncate = Enum.TextTruncate.AtEnd;
				TextXAlignment = Enum.TextXAlignment.Right;

				TextColor3 = Blend.Computed(percentInvalid, function(invalid)
					return Color3.fromRGB(255, 255, 255):Lerp(ERROR_COLOR, invalid)
				end);

				TextSize = Blend.Computed(self._isValid, function(isValid)
					return isValid and 18 or 13
				end);

				TextTransparency = Blend.Computed(props.Transparency, percentVisible, self._preview, function(parentTransparency, percent, preview)
					if preview == "" then
						return 1
					end

					return math.clamp(parentTransparency + (1 - percent), 0, 1)
				end);
			};
		};
	}
end

return NumberPreviewPane
