local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local Fzy = require("Fzy")
local Rx = require("Rx")
local Signal = require("Signal")
local ValueObject = require("ValueObject")

local CommandEntry = setmetatable({}, BasicPane)
CommandEntry.ClassName = "CommandEntry"
CommandEntry.__index = CommandEntry

function CommandEntry.new()
	local self = setmetatable(BasicPane.new(), CommandEntry)

	self._groupIcon = self._maid:Add(ValueObject.new(""))
	self._defaultIndex = self._maid:Add(ValueObject.new(0))
	self._groupName = self._maid:Add(ValueObject.new(""))
	self._groupVisible = self._maid:Add(ValueObject.new(false))
	self._isGroupHeader = self._maid:Add(ValueObject.new(false))
	self._macroDescription = self._maid:Add(ValueObject.new(""))
	self._macroName = self._maid:Add(ValueObject.new(""))
	self._model = self._maid:Add(ButtonHighlightModel.new())
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._yPosition = self._maid:Add(ValueObject.new(0))

	self.Activated = self._maid:Add(Signal.new())
	self.SearchScore = self._maid:Add(ValueObject.new(0))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._model:SetInteractionEnabled(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function CommandEntry:SetIsGroupHeader(isGroupHeader: boolean)
	self._isGroupHeader.Value = isGroupHeader
end

function CommandEntry:IsGroupHeader()
	return self._isGroupHeader.Value
end

function CommandEntry:SetGroupVisible(isVisible: boolean)
	self._groupVisible.Value = isVisible
end

function CommandEntry:SetGroupName(name: string)
	self._groupName.Value = name
end

function CommandEntry:SetGroupIcon(icon: string)
	self._groupIcon.Value = icon
end

function CommandEntry:SetName(name: string)
	self._macroName.Value = name
end

function CommandEntry:SetDescription(description: string)
	self._macroDescription.Value = description
end

function CommandEntry:GetYPosition()
	return self._yPosition.Value
end

function CommandEntry:SetDefaultIndex(index: number)
	self._defaultIndex.Value = index
end

function CommandEntry:_getMatchedString(fzyConfig, targetString, searchQuery)
	if not fzyConfig or not targetString or not searchQuery then
		return
	end

	searchQuery = string.lower(searchQuery)

	local positions = Fzy.positions(fzyConfig, searchQuery, string.lower(targetString))
	if not positions or #positions == 0 then
		return targetString
	end

	local ranges = {}
	local startPos, endPos = positions[1], positions[1]

	for i = 2, #positions do
		if positions[i] == endPos + 1 then
			endPos = positions[i]

			if i == #positions then
				table.insert(ranges, { startPos, endPos })
			end
		else
			table.insert(ranges, { startPos, endPos })
			startPos = positions[i]
			endPos = positions[i]
		end
	end

	if #ranges == 0 then
		return targetString
	end

	local finalString = ""

	for index, range in ranges do
		local start = string.sub(targetString, index == 1 and 0 or ranges[index - 1][2] + 1, range[1] - 1)
		local matched = string.sub(targetString, range[1], range[2])

		finalString ..= `{start}<font color="#d0a4f7">{matched}</font>`

		if index == #ranges then
			finalString ..= string.sub(targetString, range[2] + 1, string.len(targetString))
		end
	end

	return finalString
end

function CommandEntry:SetIsSelected(isSelected: boolean)
	self._model:SetIsChoosen(isSelected)
	self._model._isMouseOver.Value = isSelected
end

function CommandEntry:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentHighlighted = Blend.Spring(self._model:ObservePercentHighlightedTarget(), 35, 0.7)
	local percentPressed = Blend.Spring(self._model:ObservePercentPressedTarget(), 35, 0.55)
	local percentSelected = Blend.AccelTween(self._model:ObservePercentChoosenTarget(), 400)

	local foregroundColor = Blend.Computed(percentSelected, function(percent)
		return Color3.fromRGB(150, 150, 150):Lerp(Color3.fromRGB(255, 255, 255), percent)
	end);

	local fzyConfig = props.FzyConfig
	local transparency = props.Transparency

	local groupCollapsed = props.GroupCollapsed

	self._maid:GiveTask(Blend.Computed(self._macroName, self._macroDescription, props.SearchQuery, function(name, description, searchQuery)
		if searchQuery == "" then
			self.SearchScore.Value = nil
			return
		end

		self.SearchScore.Value = Fzy.score(fzyConfig, searchQuery, string.lower(`{name} {description}`))
	end):Subscribe())

	self._maid:GiveTask(self._model:ObserveIsMouseOrTouchOver():Subscribe(function(isHovered)
		if isHovered then
			return
		end

		if not isHovered then
			if self._model:IsChoosen() then
				self._model._isMouseOver.Value = true
			else
				self._model._isMouseOver.Value = false
			end
		end
	end))

	return Blend.New "Frame" {
		Name = "CommandEntry";
		BackgroundTransparency = 1;
		Parent = props.TargetParent;

		LayoutOrder = Blend.Computed(self._isGroupHeader, self.SearchScore, self._defaultIndex, function(isGroupHeader, score, defaultIndex)
			if isGroupHeader then
				return -1
			end

			return score and -(score * 10000) or defaultIndex
		end);

		Size = Blend.Computed(props.EntryHeight, function(height)
			return UDim2.new(1, 0, 0, height)
		end);

		Visible = Blend.Computed(self._isGroupHeader, groupCollapsed, props.SearchQuery, self.SearchScore, function(isGroupEntry, isCollapsed, searchQuery, searchScore)
			if isGroupEntry then
				return searchQuery == ""
			else
				if searchQuery ~= "" and searchScore then
					return searchScore > -1
				else
					return not isCollapsed
				end
			end
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
				Padding = UDim.new(0, 5);
				VerticalAlignment = Enum.VerticalAlignment.Center;
			};

			Blend.New "UIPadding" {
				PaddingBottom = UDim.new(0, 14);
				PaddingRight = UDim.new(0, 7);
				PaddingTop = UDim.new(0, 14);

				PaddingLeft = Blend.Computed(self._isGroupHeader, self._groupVisible, props.SearchQuery, function(isGroupEntry, groupVisible, searchQuery)
					if not isGroupEntry then
						if searchQuery ~= "" then
							return UDim.new(0, 7)
						else
							return UDim.new(0, not groupVisible and 30 or 7)
						end
					else
						return UDim.new(0, 7)
					end
				end);
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
				Name = "group";
				BackgroundTransparency = 1;
				LayoutOrder = 1;

				Size = Blend.Computed(self._isGroupHeader, props.SearchQuery, function(isGroupHeader)
					return isGroupHeader and UDim2.fromScale(0.5, 1) or UDim2.fromScale(0.15, 1)
				end);

				Visible = Blend.Computed(self._isGroupHeader, props.SearchQuery, function(isGroupHeader, searchQuery)
					if isGroupHeader then
						return true
					else
						return searchQuery ~= ""
					end
				end);

				Blend.New "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal;
					Padding = UDim.new(0, 5);
					VerticalAlignment = Enum.VerticalAlignment.Center;
				};

				Blend.New "ImageLabel" {
					Name = "groupIcon";
					BackgroundTransparency = 1;
					Image = self._groupIcon;
					ImageColor3 = foregroundColor;
					ImageTransparency = transparency;
					LayoutOrder = 1;
					Size = UDim2.fromOffset(15, 15);
				};

				Blend.New "TextLabel" {
					Name = "groupName";
					AutomaticSize = Enum.AutomaticSize.X;
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
					LayoutOrder = 2;
					Size = UDim2.fromOffset(0, 15);
					Text = self._groupName;
					TextColor3 = foregroundColor;
					TextSize = 15;
					TextTransparency = transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;
				};
			};

			Blend.New "ImageLabel" {
				Name = "groupArrow";
				BackgroundTransparency = 1;
				Image = "rbxassetid://6034818365";
				ImageColor3 = foregroundColor;
				ImageTransparency = transparency;
				LayoutOrder = 2;
				Size = UDim2.fromScale(1, 1);

				Visible = Blend.Computed(self._isGroupHeader, props.SearchQuery, function(isGroupHeader, searchQuery)
					if isGroupHeader then
						return false
					else
						return searchQuery ~= ""
					end
				end);

				Blend.New "UIAspectRatioConstraint" {
					AspectRatio = 1;
				};
			};

			Blend.New "Frame" {
				Name = "container";
				BackgroundTransparency = 1;
				LayoutOrder = 3;
				Position = UDim2.fromScale(0.081324, 0);
				Size = UDim2.fromScale(0.851873, 1);

				Visible = self._isGroupHeader:Observe():Pipe({
					Rx.map(function(isGroupEntry)
						return not isGroupEntry
					end)
				});

				Blend.New "UIListLayout" {
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
					VerticalAlignment = Enum.VerticalAlignment.Center;
				};

				Blend.New "TextLabel" {
					Name = "commandName";
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
					LayoutOrder = 2;
					RichText = true;
					Size = UDim2.new(1, 0, 0, 15);
					TextColor3 = Color3.fromRGB(255, 255, 255);
					TextSize = 15;
					TextTransparency = transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;

					Text = Blend.Computed(self._macroName, props.SearchQuery, function(macroName, searchQuery)
						if searchQuery ~= "" then
							return self:_getMatchedString(fzyConfig, macroName, searchQuery)
						else
							return macroName
						end
					end);
				};

				Blend.New "TextLabel" {
					Name = "commandDescription";
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
					LayoutOrder = 2;
					RichText = true;
					Size = UDim2.new(1, 0, 0, 15);
					TextSize = 13;
					TextTransparency = transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;

					TextColor3 = Blend.Computed(percentSelected, function(percent)
						return Color3.fromRGB(110, 110, 110):Lerp(Color3.fromRGB(255, 255, 255), percent)
					end);

					Text = Blend.Computed(self._macroDescription, props.SearchQuery, function(description, searchQuery)
						if searchQuery ~= "" then
							return self:_getMatchedString(fzyConfig, description, searchQuery)
						else
							return description
						end
					end);
				};
			};

			Blend.New "Frame" {
				Name = "collapsed";
				BackgroundTransparency = 1;
				Size = UDim2.fromScale(1, 1);
				LayoutOrder = 4;

				Blend.New "UIAspectRatioConstraint" {
					AspectRatio = 1;
				};

				Blend.New "ImageLabel" {
					Name = "collapseArrow";
					BackgroundTransparency = 1;
					Image = "rbxassetid://6034818365";
					ImageColor3 = foregroundColor;
					ImageTransparency = transparency;
					LayoutOrder = 3;
					Size = UDim2.fromScale(1, 1);
					Visible = self._isGroupHeader;

					Rotation = Blend.Computed(groupCollapsed, function(isCollapsed)
						return isCollapsed and 0 or 90
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
			Visible = self:ObserveVisible();
			ZIndex = 5;

			[Blend.OnEvent "Activated"] = function()
				self.Activated:Fire()
			end;

			[Blend.Instance] = function(button)
				self._model:SetButton(button)
			end;
		};

		Blend.New "Frame" {
			Name = "shortcut";
			AnchorPoint = Vector2.new(1, 0.5);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundColor3 = Color3.fromRGB(50, 50, 50);
			BackgroundTransparency = transparency;
			LayoutOrder = 3;
			Position = UDim2.new(1, -7, 0.5, 0);
			Size = UDim2.fromOffset(0, 20);
			Visible = false;

			Blend.New "UIPadding" {
				PaddingBottom = UDim.new(0, 5);
				PaddingLeft = UDim.new(0, 10);
				PaddingRight = UDim.new(0, 10);
				PaddingTop = UDim.new(0, 5);
			};

			Blend.New "UICorner" {
				CornerRadius = UDim.new(0, 5);
			};

			Blend.New "UIStroke" {
				Color = Color3.fromRGB(35, 35, 35);
				Transparency = transparency;
			};

			Blend.New "TextLabel" {
				Name = "label";
				AnchorPoint = Vector2.new(0.5, 0.5);
				AutomaticSize = Enum.AutomaticSize.X;
				BackgroundTransparency = 1;
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
				Position = UDim2.fromScale(0.5, 0.5);
				Size = UDim2.fromOffset(0, 14);
				Text = "Space";
				TextColor3 = Color3.fromRGB(110, 110, 110);
				TextTransparency = transparency;
			};
		};
	}
end

return CommandEntry