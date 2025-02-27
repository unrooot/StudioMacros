local require = require(script.Parent.loader).load(script)

local UserInputService = game:GetService("UserInputService")

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local Fzy = require("Fzy")
local SearchUtils = require("SearchUtils")
local Signal = require("Signal")
local ValueObject = require("ValueObject")

local ColorEntry = setmetatable({}, BasicPane)
ColorEntry.ClassName = "ColorEntry"
ColorEntry.CustomResultType = "Color"
ColorEntry.__index = ColorEntry

function ColorEntry.new()
	local self = setmetatable(BasicPane.new(), ColorEntry)

	self._colorName = self._maid:Add(ValueObject.new(""))
	self._defaultIndex = self._maid:Add(ValueObject.new(0))
	self._model = self._maid:Add(ButtonHighlightModel.new())
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._yPosition = self._maid:Add(ValueObject.new(0))

	self.Activated = self._maid:Add(Signal.new())
	self.Color = self._maid:Add(ValueObject.new(Color3.new(1, 1, 1)))
	self.SearchScore = self._maid:Add(ValueObject.new(0))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._model:SetInteractionEnabled(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function ColorEntry:SetColorName(colorName: string)
	self._colorName.Value = colorName
end

function ColorEntry:SetColor(color: Color3)
	self.Color.Value = color
end

function ColorEntry:GetYPosition()
	return self._yPosition.Value
end

function ColorEntry:SetDefaultIndex(index: number)
	self._defaultIndex.Value = index
end

function ColorEntry:SetIsSelected(isSelected: boolean)
	self._model:SetIsChoosen(isSelected)
	self._model._isMouseOver.Value = isSelected
end

function ColorEntry:GetData()
	return self.Color.Value
end

function ColorEntry:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentHighlighted = Blend.Spring(self._model:ObservePercentHighlightedTarget(), 35, 0.7)
	local percentPressed = Blend.Spring(self._model:ObservePercentPressedTarget(), 35, 0.55)
	local percentSelected = Blend.AccelTween(self._model:ObservePercentChoosenTarget(), 400)

	local foregroundColor = Blend.Computed(percentSelected, function(percent)
		return Color3.fromRGB(150, 150, 150):Lerp(Color3.fromRGB(255, 255, 255), percent)
	end);

	local fzyConfig = props.FzyConfig
	local transparency = props.Transparency

	self._maid:GiveTask(Blend.Computed(self._colorName, props.SearchQuery, function(colorName, searchQuery)
		if searchQuery == "" then
			self.SearchScore.Value = nil
			return
		end

		self.SearchScore.Value = Fzy.score(fzyConfig, searchQuery, string.lower(colorName))
	end):Subscribe())

	local verticalPadding = Blend.Computed(props.EntryHeight, function(height)
		return UDim.new(0, height == 45 and 14 or 10)
	end);

	return Blend.New "Frame" {
		Name = "ColorEntry";
		BackgroundTransparency = 1;
		Parent = props.TargetParent;

		LayoutOrder = Blend.Computed(self.SearchScore, self._defaultIndex, function(score, defaultIndex)
			return score and -(score * 10000) or defaultIndex
		end);

		Size = Blend.Computed(props.EntryHeight, function(height)
			return UDim2.new(1, 0, 0, height)
		end);

		Visible = Blend.Computed(props.CustomResult, props.Enabled, props.SearchQuery, self.SearchScore, function(customResult, isEnabled, searchQuery, searchScore)
			if not customResult then
				return false
			elseif isEnabled then
				if searchQuery ~= "" and searchScore then
					return searchScore > 0
				else
					return true
				end
			end

			return false
		end);

		ZIndex = Blend.Computed(self.SearchScore, self._defaultIndex, function(score, defaultIndex)
			return score and -(score * 10000) or defaultIndex
		end);

		[Blend.OnChange "AbsolutePosition"] = function(position)
			if not self:IsVisible() then
				return
			end

			self._yPosition.Value = math.round(position.Y)
		end;

		Blend.New "Frame" {
			Name = "wrapper";
			BackgroundColor3 = Color3.fromRGB(50, 50, 50);
			Size = UDim2.fromScale(1, 1);

			BackgroundTransparency = Blend.Computed(transparency, percentHighlighted, function(percent, percentHighlight)
				return 1 - percentHighlight + percent
			end);

			Blend.New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalFlex = Enum.UIFlexAlignment.Fill;
				Padding = UDim.new(0, 10);
				VerticalAlignment = Enum.VerticalAlignment.Center;
			};

			Blend.New "UIPadding" {
				PaddingBottom = verticalPadding;
				PaddingLeft = UDim.new(0, 7);
				PaddingRight = UDim.new(0, 7);
				PaddingTop = verticalPadding;
			};

			Blend.New "UIStroke" {
				Color = Color3.fromRGB(85, 85, 85);
				Transparency = Blend.Computed(transparency, percentHighlighted, function(percent, percentHighlight)
					return math.clamp(1 - percentHighlight + percent, 0, 1)
				end);
			};

			Blend.New "UICorner" {
				CornerRadius = UDim.new(0, 5);
			};

			Blend.New "Frame" {
				Name = "colorPreview";
				BackgroundColor3 = self.Color;
				BackgroundTransparency = transparency;
				Size = UDim2.fromScale(1.5, 1.5);

				Blend.New "UIAspectRatioConstraint" {
					AspectRatio = 1;
				};

				Blend.New "UICorner" {
					CornerRadius = UDim.new(0, 5);
				};
			};

			Blend.New "Frame" {
				Name = "container";
				BackgroundTransparency = 1;
				LayoutOrder = 3;
				Size = UDim2.fromScale(0.85, 1);

				Blend.New "TextLabel" {
					Name = "colorName";
					AnchorPoint = Vector2.new(0, 0.5);
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
					LayoutOrder = 2;
					Position = UDim2.fromScale(0, 0.5);
					RichText = true;
					Size = UDim2.new(1, 0, 0, 15);
					TextColor3 = Color3.fromRGB(255, 255, 255);
					TextSize = 15;
					TextTransparency = transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;

					Text = Blend.Computed(self._colorName, props.SearchQuery, function(colorName, searchQuery)
						if searchQuery ~= "" then
							return SearchUtils.getMatchedString(fzyConfig, colorName, searchQuery)
						else
							return colorName
						end
					end);
				};

				Blend.New "TextLabel" {
					Name = "colorValue";
					AnchorPoint = Vector2.new(1, 0.5);
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
					LayoutOrder = 2;
					Position = UDim2.fromScale(1, 0.5);
					Size = UDim2.new(1, 0, 0, 15);
					TextSize = 13;
					TextTransparency = transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Right;

					Text = Blend.Computed(self.Color, function(color)
						if not color then
							return ""
						end

						return `{math.round(color.R * 255)}, {math.round(color.G * 255)}, {math.round(color.B * 255)}`
					end);

					TextColor3 = Blend.Computed(percentSelected, function(percent)
						return Color3.fromRGB(110, 110, 110):Lerp(Color3.fromRGB(255, 255, 255), percent)
					end);
				};
			};
		};

		Blend.New "Frame" {
			Name = "divider";
			AnchorPoint = Vector2.new(0, 1);
			BackgroundColor3 = Color3.fromRGB(35, 35, 35);
			BackgroundTransparency = transparency;
			Position = UDim2.new(0, 0, 1, 2);
			Size = UDim2.new(1, 0, 0, 1);
		};

		Blend.New "TextButton" {
			Name = "button";
			BackgroundTransparency = 1;
			Size = UDim2.fromScale(1, 1);
			Visible = props.Enabled;
			ZIndex = 5;

			[Blend.OnEvent "Activated"] = function()
				local shiftPressed = false
				for _, inputObject in UserInputService:GetKeysPressed() do
					if inputObject.KeyCode == Enum.KeyCode.LeftShift then
						shiftPressed = true
						break
					end
				end

				self.Activated:Fire(shiftPressed)
			end;

			[Blend.Instance] = function(button)
				self._model:SetButton(button)
			end;
		};
	}
end

return ColorEntry