local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local Fzy = require("Fzy")
local SearchUtils = require("SearchUtils")
local Signal = require("Signal")
local String = require("String")
local ValueObject = require("ValueObject")

local FontStyleEntry = setmetatable({}, BasicPane)
FontStyleEntry.ClassName = "FontStyleEntry"
FontStyleEntry.CustomResultType = "FontStyle"
FontStyleEntry.__index = FontStyleEntry

function FontStyleEntry.new()
	local self = setmetatable(BasicPane.new(), FontStyleEntry)

	self._compatibleFonts = {}

	self._defaultIndex = self._maid:Add(ValueObject.new(0))
	self._enumWeight = self._maid:Add(ValueObject.new(nil))
	self._fontStyleName = self._maid:Add(ValueObject.new(""))
	self._fontWeight = self._maid:Add(ValueObject.new(nil))
	self._fontWeightName = self._maid:Add(ValueObject.new(""))
	self._isItalic = self._maid:Add(ValueObject.new(false))
	self._model = self._maid:Add(ButtonHighlightModel.new())
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._styleCount = self._maid:Add(ValueObject.new(0))
	self._yPosition = self._maid:Add(ValueObject.new(0))

	self.Activated = self._maid:Add(Signal.new())
	self.SearchScore = self._maid:Add(ValueObject.new(0))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function FontStyleEntry:SetFontCompatible(font: Font)
	self._compatibleFonts[font.Family] = true
end

function FontStyleEntry:IsFontCompatible(font: Font)
	return self._compatibleFonts[font.Family]
end

function FontStyleEntry:SetStyleName(styleName: string)
	if not styleName then
		return
	end

	self._fontStyleName.Value = styleName

	local formattedName = String.toCamelCase(styleName)
	local cleanStyleName = formattedName:gsub("Italic", "")

	local weights = Enum.FontWeight:GetEnumItems()
	local weightNames = {}
	for _, weight in weights do
		weightNames[weight.Name] = true
	end

	local isValidWeight = weightNames[cleanStyleName]
	local weight

	if not isValidWeight then
		if formattedName == "Italic" then
			weight = Enum.FontWeight.Regular
			isValidWeight = true
		elseif cleanStyleName == "Black" then
			weight = Enum.FontWeight.Heavy
			isValidWeight = true
		end
	end

	if isValidWeight then
		weight = weight or Enum.FontWeight[cleanStyleName]
		self._fontWeight.Value = weight.Value
		self._fontWeightName.Value = weight.Name
		self._enumWeight.Value = weight
	end
end

function FontStyleEntry:GetFontWeight()
	return self._fontWeight.Value or 100
end

function FontStyleEntry:SetIsItalic(isItalic: boolean)
	self._isItalic.Value = isItalic
end

function FontStyleEntry:SetStyleCount(count: number)
	self._styleCount.Value = count
end

function FontStyleEntry:GetYPosition()
	return self._yPosition.Value
end

function FontStyleEntry:SetDefaultIndex(index: number)
	self._defaultIndex.Value = index
end

function FontStyleEntry:SetIsSelected(isSelected: boolean)
	self._model:SetIsChoosen(isSelected)
	self._model._isMouseOver.Value = isSelected
end

function FontStyleEntry:GetData()
	return self._enumWeight.Value, self._isItalic.Value
end

function FontStyleEntry:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentHighlighted = Blend.Spring(self._model:ObservePercentHighlightedTarget(), 35, 0.7)
	local percentPressed = Blend.Spring(self._model:ObservePercentPressedTarget(), 35, 0.55)
	local percentSelected = Blend.AccelTween(self._model:ObservePercentChoosenTarget(), 400)

	local foregroundColor = Blend.Computed(percentSelected, function(percent)
		return Color3.fromRGB(150, 150, 150):Lerp(Color3.fromRGB(255, 255, 255), percent)
	end);

	local fzyConfig = props.FzyConfig
	local transparency = props.Transparency

	self._maid:GiveTask(Blend.Computed(self._fontStyleName, self._fontWeightName, props.SearchQuery, function(styleName, weightName, searchQuery)
		if searchQuery == "" then
			self.SearchScore.Value = nil
			return
		end

		self.SearchScore.Value = Fzy.score(fzyConfig, searchQuery, `{string.lower(styleName)} {string.lower(weightName)}`)
	end):Subscribe())

	return Blend.New "Frame" {
		Name = "FontStyleEntry";
		BackgroundTransparency = 1;
		Parent = props.TargetParent;

		LayoutOrder = Blend.Computed(self.SearchScore, self._defaultIndex, function(score, defaultIndex)
			return score and -(score * 10000) or defaultIndex
		end);

		Size = Blend.Computed(props.EntryHeight, function(height)
			if height == 45 then
				return UDim2.new(1, 0, 0, 60)
			else
				return UDim2.new(1, 0, 0, 40)
			end
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

			Blend.New "UIPadding" {
				PaddingBottom = UDim.new(0, 14);
				PaddingLeft = UDim.new(0, 7);
				PaddingRight = UDim.new(0, 7);
				PaddingTop = UDim.new(0, 14);
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

			Blend.New "TextLabel" {
				Name = "styles";
				LayoutOrder = 2;
				Position = UDim2.fromScale(1, 0.5);
				AnchorPoint = Vector2.new(1, 0.5);
				Size = UDim2.new(1, 0, 0, 15);
				BackgroundTransparency = 1;
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
				TextColor3 = Color3.fromRGB(85, 85, 85);
				TextWrapped = true;
				TextXAlignment = Enum.TextXAlignment.Right;

				Text = Blend.Computed(self._fontWeight, function(weight)
					return weight or ""
				end);
			};

			Blend.New "Frame" {
				Name = "container";
				LayoutOrder = 9;
				Size = UDim2.fromScale(0.9, 1);
				BackgroundTransparency = 1;

				Blend.New "UIListLayout" {
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
					VerticalAlignment = Enum.VerticalAlignment.Center;
				};

				Blend.New "TextLabel" {
					Name = "textPreview";
					AnchorPoint = Vector2.new(0, 0.5);
					BackgroundTransparency = 1;
					LayoutOrder = 2;
					Position = UDim2.fromScale(0, 0.5);
					RichText = true;
					Size = UDim2.new(1, 0, 0, 20);
					TextColor3 = Color3.fromRGB(255, 255, 255);
					TextSize = 20;
					TextTruncate = Enum.TextTruncate.AtEnd;
					TextXAlignment = Enum.TextXAlignment.Left;

					FontFace = Blend.Computed(props.TargetFont, self._enumWeight, self._isItalic, function(font, fontWeight, isItalic)
						if not font then
							return Font.new("rbxasset://fonts/families/SourceSansPro.json")
						end

						local family = font.Family
						local style = isItalic and Enum.FontStyle.Italic or Enum.FontStyle.Normal

						return Font.new(family, fontWeight or Enum.FontWeight.Regular, style)
					end);

					Text = Blend.Computed(props.EntryHeight, self._fontStyleName, self._fontWeightName, props.SearchQuery, function(height, fontStyleName, fontWeightName, searchQuery)
						if height == 45 then
							return SearchUtils.getMatchedString(fzyConfig, fontStyleName, searchQuery)
						else
							return SearchUtils.getMatchedString(fzyConfig, fontWeightName, searchQuery)
						end
					end);
				};

				Blend.New "TextLabel" {
					Name = "fontWeightName";
					AnchorPoint = Vector2.new(1, 0.5);
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
					LayoutOrder = 2;
					Position = UDim2.fromScale(1, 0.5);
					RichText = true;
					Size = UDim2.new(1, 0, 0, 15);
					TextColor3 = Color3.fromRGB(110, 110, 110);
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;

					Text = Blend.Computed(self._fontWeightName, props.SearchQuery, function(fontWeightName, searchQuery)
						if searchQuery ~= "" then
							return SearchUtils.getMatchedString(fzyConfig, fontWeightName, searchQuery)
						else
							return fontWeightName
						end
					end);

					Visible = Blend.Computed(props.EntryHeight, function(height)
						return height == 45
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
				self.Activated:Fire()
			end;

			[Blend.Instance] = function(button)
				self._model:SetButton(button)
			end;
		};
	}
end

return FontStyleEntry