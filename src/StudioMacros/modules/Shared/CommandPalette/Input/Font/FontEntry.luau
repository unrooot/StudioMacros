local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local Fzy = require("Fzy")
local SearchUtils = require("SearchUtils")
local Signal = require("Signal")
local ValueObject = require("ValueObject")

local FontEntry = setmetatable({}, BasicPane)
FontEntry.ClassName = "FontEntry"
FontEntry.CustomResultType = "Font"
FontEntry.__index = FontEntry

function FontEntry.new()
	local self = setmetatable(BasicPane.new(), FontEntry)

	self._defaultIndex = self._maid:Add(ValueObject.new(0))
	self._fontName = self._maid:Add(ValueObject.new(""))
	self._model = self._maid:Add(ButtonHighlightModel.new())
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._styleCount = self._maid:Add(ValueObject.new(0))
	self._yPosition = self._maid:Add(ValueObject.new(0))

	self.Activated = self._maid:Add(Signal.new())
	self.Font = self._maid:Add(ValueObject.new(nil))
	self.SearchScore = self._maid:Add(ValueObject.new(0))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function FontEntry:SetFontName(fontName: string)
	self._fontName.Value = fontName
end

function FontEntry:SetStyleCount(count: number)
	self._styleCount.Value = count
end

function FontEntry:GetYPosition()
	return self._yPosition.Value
end

function FontEntry:SetDefaultIndex(index: number)
	self._defaultIndex.Value = index
end

function FontEntry:SetIsSelected(isSelected: boolean)
	self._model:SetIsChoosen(isSelected)
	self._model._isMouseOver.Value = isSelected
end

function FontEntry:GetData()
	return self.Font.Value
end

function FontEntry:GetFontName()
	return self._fontName.Value
end

function FontEntry:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentHighlighted = Blend.Spring(self._model:ObservePercentHighlightedTarget(), 35, 0.7)
	local percentPressed = Blend.Spring(self._model:ObservePercentPressedTarget(), 35, 0.55)
	local percentSelected = Blend.AccelTween(self._model:ObservePercentChoosenTarget(), 400)

	local foregroundColor = Blend.Computed(percentSelected, function(percent)
		return Color3.fromRGB(150, 150, 150):Lerp(Color3.fromRGB(255, 255, 255), percent)
	end);

	local fzyConfig = props.FzyConfig
	local transparency = props.Transparency

	self._maid:GiveTask(Blend.Computed(self._fontName, props.SearchQuery, function(fontName, searchQuery)
		if searchQuery == "" then
			self.SearchScore.Value = nil
			return
		end

		self.SearchScore.Value = Fzy.score(fzyConfig, searchQuery, string.lower(fontName))
	end):Subscribe())

	return Blend.New "Frame" {
		Name = "FontEntry";
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

				Text = Blend.Computed(self._styleCount, function(count)
					return `{count} {count == 1 and "style" or "styles"}`
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
					LayoutOrder = 2;
					Position = UDim2.fromScale(0, 0.5);
					AnchorPoint = Vector2.new(0, 0.5);
					Size = UDim2.new(1, 0, 0, 20);
					BackgroundTransparency = 1;
					RichText = true;
					TextColor3 = Color3.fromRGB(255, 255, 255);
					TextSize = 20;
					TextTruncate = Enum.TextTruncate.AtEnd;
					TextXAlignment = Enum.TextXAlignment.Left;

					Text = Blend.Computed(props.EntryHeight, props.FontPreviewText, self._fontName, props.SearchQuery, function(height, fontPreviewText, fontName, searchQuery)
						if height == 45 then
							return SearchUtils.getMatchedString(fzyConfig, fontPreviewText, searchQuery)
						else
							return SearchUtils.getMatchedString(fzyConfig, fontName, searchQuery)
						end
					end);

					FontFace = Blend.Computed(self.Font, function(font)
						if not font then
							return Font.new("rbxasset://fonts/families/SourceSansPro.json")
						end

						return font
					end);
				};

				Blend.New "TextLabel" {
					Name = "fontName";
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

					Text = Blend.Computed(self._fontName, props.SearchQuery, function(fontName, searchQuery)
						if searchQuery ~= "" then
							return SearchUtils.getMatchedString(fzyConfig, fontName, searchQuery)
						else
							return fontName
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

return FontEntry