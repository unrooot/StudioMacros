local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local Rx = require("Rx")
local Signal = require("Signal")
local ValueObject = require("ValueObject")

local CommandEntry = setmetatable({}, BasicPane)
CommandEntry.ClassName = "CommandEntry"
CommandEntry.__index = CommandEntry

function CommandEntry.new()
	local self = setmetatable(BasicPane.new(), CommandEntry)

	self._groupCollapsed = self._maid:Add(ValueObject.new(false))
	self._groupIcon = self._maid:Add(ValueObject.new(""))
	self._groupName = self._maid:Add(ValueObject.new(""))
	self._groupVisible = self._maid:Add(ValueObject.new(false))
	self._isGroupEntry = self._maid:Add(ValueObject.new(false))
	self._macroDescription = self._maid:Add(ValueObject.new(""))
	self._macroName = self._maid:Add(ValueObject.new(""))
	self._model = self._maid:Add(ButtonHighlightModel.new())
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))

	self.Activated = self._maid:Add(Signal.new())

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._model:SetInteractionEnabled(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0

	end))

	return self
end

function CommandEntry:ObserveIsCollapsed()
	return self._groupCollapsed:Observe()
end

function CommandEntry:SetIsGroupEntry(isGroupEntry: boolean)
	self._isGroupEntry.Value = isGroupEntry
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

function CommandEntry:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentHighlighted = Blend.Spring(self._model:ObservePercentHighlightedTarget(), 35, 0.7)
	local percentPressed = Blend.Spring(self._model:ObservePercentPressedTarget(), 35, 0.55)
	local percentSelected = Blend.AccelTween(self._model:ObservePercentChoosenTarget(), 400)

	local foregroundColor = Blend.Computed(percentSelected, function(percent)
		return Color3.fromRGB(150, 150, 150):Lerp(Color3.fromRGB(255, 255, 255), percent)
	end);

	return Blend.New "Frame" {
		Name = "CommandEntry";
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 0, 45);

		LayoutOrder = self._isGroupEntry:Observe():Pipe({
			Rx.map(function(isGroupEntry)
				return isGroupEntry and -1 or 0
			end)
		});

		Blend.New "Frame" {
			Name = "wrapper";
			BackgroundColor3 = Color3.fromRGB(50, 50, 50);
			BackgroundTransparency = 1;
			Size = UDim2.fromScale(1, 1);

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

				PaddingLeft = Blend.Computed(self._isGroupEntry, self._groupVisible, function(isGroupEntry, groupVisible)
					return UDim.new(0, not isGroupEntry and not groupVisible and 30 or 7)
				end);
			};

			Blend.New "UIStroke" {
				Color = Color3.fromRGB(85, 85, 85);
				Enabled = false;
			};

			Blend.New "UICorner" {
				CornerRadius = UDim.new(0, 5);
			};

			Blend.New "Frame" {
				Name = "group";
				BackgroundTransparency = 1;
				Size = UDim2.fromScale(0.5, 1);
				Visible = self._isGroupEntry;

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
					ImageTransparency = props.Transparency;
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
					TextTransparency = props.Transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;
				};
			};

			Blend.New "Frame" {
				Name = "container";
				BackgroundTransparency = 1;
				LayoutOrder = 2;
				Position = UDim2.fromScale(0.081324, 0);
				Size = UDim2.fromScale(0.851873, 1);

				Visible = self._isGroupEntry:Observe():Pipe({
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
					Text = self._macroName;
					TextColor3 = Color3.fromRGB(255, 255, 255);
					TextSize = 15;
					TextTransparency = props.Transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;
				};

				Blend.New "TextLabel" {
					Name = "commandDescription";
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
					LayoutOrder = 2;
					RichText = true;
					Size = UDim2.new(1, 0, 0, 15);
					Text = self._macroDescription;
					TextColor3 = Color3.fromRGB(110, 110, 110);
					TextSize = 13;
					TextTransparency = props.Transparency;
					TextWrapped = true;
					TextXAlignment = Enum.TextXAlignment.Left;
				};
			};

			Blend.New "ImageLabel" {
				Name = "arrow";
				BackgroundTransparency = 1;
				Image = "rbxassetid://6034818365";
				ImageColor3 = foregroundColor;
				ImageTransparency = props.Transparency;
				LayoutOrder = 3;
				Size = UDim2.fromScale(1, 1);
				Visible = self._isGroupEntry;

				Blend.New "UIAspectRatioConstraint" {
					AspectRatio = 1;
				};
			};
		};

		Blend.New "Frame" {
			Name = "divider";
			AnchorPoint = Vector2.new(0, 1);
			BackgroundColor3 = Color3.fromRGB(35, 35, 35);
			BackgroundTransparency = props.Transparency;
			Position = UDim2.new(0, 0, 1, 2);
			Size = UDim2.new(1, 0, 0, 1);
		};

		Blend.New "TextButton" {
			Name = "button";
			BackgroundTransparency = 1;
			Size = UDim2.fromScale(1, 1);
			Visible = false;
			ZIndex = 5;
		};

		Blend.New "Frame" {
			Name = "shortcut";
			AnchorPoint = Vector2.new(1, 0.5);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundColor3 = Color3.fromRGB(50, 50, 50);
			BackgroundTransparency = props.Transparency;
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
				Transparency = props.Transparency;
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
				TextTransparency = props.Transparency;
			};
		};
	}
end

return CommandEntry