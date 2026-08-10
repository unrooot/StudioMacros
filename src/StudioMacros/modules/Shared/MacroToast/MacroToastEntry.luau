local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local Rx = require("Rx")
local Signal = require("Signal")
local SpringObject = require("SpringObject")
local TextServiceUtils = require("TextServiceUtils")
local ValueObject = require("ValueObject")
local cancellableDelay = require("cancellableDelay")

local DISMISS_ACCEL = 100
local DISPLAY_TIME = 1
local FADE_TIME = 0.3
local HORIZONTAL_PADDING = 12
local REVEAL_ACCEL = 400

local CONTENT_GAP = 7
local FONT_FACE = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local ICON_SIZE = 15
local NAME_TEXT_SIZE = 15
local SWATCH_SIZE = 12
local VALUE_HEIGHT = 20
local VALUE_PADDING = 7
local VALUE_TEXT_SIZE = 13

local IMPULSE_PEAK = 0.1
local IMPULSE_VELOCITY = 4

local MacroToastEntry = setmetatable({}, BasicPane)
MacroToastEntry.ClassName = "MacroToastEntry"
MacroToastEntry.Height = 34
MacroToastEntry.__index = MacroToastEntry

local function formatToggleValue(value): string
	if typeof(value) == "boolean" then
		return value and "true" or "false"
	elseif typeof(value) == "number" then
		return tostring(math.round(value * 100) / 100)
	end

	return tostring(value)
end

function MacroToastEntry.new(macroName: string, groupIcon: string?)
	local self = setmetatable(BasicPane.new(), MacroToastEntry)

	self._groupIcon = self._maid:Add(ValueObject.new(groupIcon or ""))
	self._impulse = self._maid:Add(SpringObject.new(0, 15, 0.9))
	self._macroName = self._maid:Add(ValueObject.new(macroName))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._valueColor = self._maid:Add(ValueObject.new(Color3.new()))
	self._valueKind = self._maid:Add(ValueObject.new("none"))
	self._valueText = self._maid:Add(ValueObject.new(""))

	self.Finished = self._maid:Add(Signal.new())
	self.LayoutOrder = self._maid:Add(ValueObject.new(0))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function MacroToastEntry:GetMacroName(): string
	return self._macroName.Value
end

function MacroToastEntry:SetToggleValue(value)
	if value == nil then
		self._valueKind.Value = "none"
		self._valueText.Value = ""
	elseif typeof(value) == "Color3" then
		self._valueColor.Value = value
		self._valueKind.Value = "color"
		self._valueText.Value = ""
	else
		self._valueKind.Value = "text"
		self._valueText.Value = formatToggleValue(value)
	end
end

function MacroToastEntry:Present()
	self:Show()
	self:_armDismiss()
end

function MacroToastEntry:Bump()
	self._impulse:Impulse(IMPULSE_VELOCITY)
	self:_armDismiss()
end

function MacroToastEntry:Dismiss()
	if not self:IsVisible() then
		return
	end

	self:Hide()

	self._maid._timer = cancellableDelay(FADE_TIME, function()
		self.Finished:Fire()
	end)
end

function MacroToastEntry:_armDismiss()
	self._maid._timer = cancellableDelay(DISPLAY_TIME, function()
		self:Dismiss()
	end)
end

function MacroToastEntry:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 40, 0.7)
	local percentAlpha = Blend.AccelTween(target, target:Pipe({
		Rx.map(function(value)
			return value == 1 and REVEAL_ACCEL or DISMISS_ACCEL
		end)
	}))

	local transparency = Blend.Computed(percentAlpha, function(percent)
		return 1 - percent
	end)

	local percentImpulse = self._impulse:ObserveRenderStepped()
	local percentFlash = Blend.Computed(percentImpulse, function(impulse)
		return math.clamp(impulse / IMPULSE_PEAK, 0, 1)
	end)

	local wrapperSize = self._maid:Add(Blend.State(Vector2.zero))

	local wrapperPosition = Blend.Computed(percentVisible, function(percent)
		return UDim2.new(0.5, 0, 0.5, (1 - percent) * 20)
	end)

	local nameSize = TextServiceUtils.observeSizeForLabelProps({
		FontFace = FONT_FACE;
		Text = self._macroName;
		TextSize = NAME_TEXT_SIZE;
	}):Pipe({
		Rx.startWith({ Vector2.zero });
	})

	local valueTextSize = TextServiceUtils.observeSizeForLabelProps({
		FontFace = FONT_FACE;
		Text = self._valueText;
		TextSize = VALUE_TEXT_SIZE;
	}):Pipe({
		Rx.startWith({ Vector2.zero });
	})

	local valueWidth = Blend.Computed(valueTextSize, self._valueKind, function(size, kind)
		if kind == "color" then
			return (VALUE_PADDING * 2) + SWATCH_SIZE
		elseif kind == "text" then
			return (VALUE_PADDING * 2) + math.ceil(size.X)
		end

		return 0
	end)

	local wrapperWidth = Blend.Computed(nameSize, valueWidth, self._groupIcon, function(name, value, icon)
		local width = (HORIZONTAL_PADDING * 2) + math.ceil(name.X)

		if icon ~= "" then
			width += ICON_SIZE + CONTENT_GAP
		end

		if value > 0 then
			width += CONTENT_GAP + value
		end

		return width
	end)

	return Blend.New "Frame" {
		Name = "MacroToastEntry";
		BackgroundTransparency = 1;
		LayoutOrder = self.LayoutOrder;
		Parent = props and props.Parent;
		Size = UDim2.new(1, 0, 0, MacroToastEntry.Height);

		Visible = Blend.Computed(percentAlpha, function(percent)
			return percent > 0.001
		end);

		Blend.New "ImageLabel" {
			Name = "shadow";
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = 1;
			Image = "rbxassetid://6150493168";
			Position = wrapperPosition;
			ScaleType = Enum.ScaleType.Slice;
			SliceCenter = Rect.new(Vector2.new(100, 100), Vector2.new(100, 100));
			SliceScale = 0.4;
			ZIndex = -10;

			Size = Blend.Computed(wrapperSize, function(size)
				return UDim2.fromOffset(size.X + 50, size.Y + 50)
			end);

			ImageColor3 = Blend.Computed(percentFlash, function(percent)
				return Color3.fromRGB(0, 0, 0):Lerp(Color3.fromRGB(197, 156, 242), percent * 0.4)
			end);

			ImageTransparency = Blend.Computed(transparency, percentFlash, function(percent, flash)
				return 0.9 + (percent * 0.1) - (flash * 0.08)
			end);
		};

		Blend.New "Frame" {
			Name = "wrapper";
			AnchorPoint = Vector2.new(0.5, 0.5);
			BackgroundTransparency = transparency;
			Position = wrapperPosition;

			Size = Blend.Computed(wrapperWidth, function(width)
				return UDim2.fromOffset(width, MacroToastEntry.Height)
			end);

			BackgroundColor3 = Blend.Computed(percentFlash, function(percent)
				return Color3.fromRGB(30, 30, 30):Lerp(Color3.fromRGB(40, 40, 40), percent)
			end);

			[Blend.OnChange "AbsoluteSize"] = function(size)
				wrapperSize.Value = size
			end;

			Blend.New "UIScale" {
				Scale = Blend.Computed(percentVisible, percentImpulse, function(percent, impulse)
					return 0.9 + (percent * 0.1) + impulse
				end);
			};

			Blend.New "UICorner" {
				CornerRadius = UDim.new(0, 10);
			};

			Blend.New "UIStroke" {
				Color = Color3.fromRGB(40, 40, 40);
				Transparency = transparency;
			};

			Blend.New "UIPadding" {
				PaddingLeft = UDim.new(0, HORIZONTAL_PADDING);
				PaddingRight = UDim.new(0, HORIZONTAL_PADDING);
			};

			Blend.New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Center;
				Padding = UDim.new(0, 7);
				VerticalAlignment = Enum.VerticalAlignment.Center;
			};

			Blend.New "ImageLabel" {
				Name = "groupIcon";
				BackgroundTransparency = 1;
				Image = self._groupIcon;
				ImageColor3 = Color3.fromRGB(197, 156, 242);
				ImageTransparency = transparency;
				LayoutOrder = 1;
				Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE);

				Visible = Blend.Computed(self._groupIcon, function(icon)
					return icon ~= ""
				end);
			};

			Blend.New "TextLabel" {
				Name = "macroName";
				BackgroundTransparency = 1;
				FontFace = FONT_FACE;
				LayoutOrder = 2;
				Text = self._macroName;
				TextColor3 = Color3.fromRGB(255, 255, 255);
				TextSize = NAME_TEXT_SIZE;
				TextTransparency = transparency;
				TextXAlignment = Enum.TextXAlignment.Left;

				Size = Blend.Computed(nameSize, function(size)
					return UDim2.fromOffset(math.ceil(size.X), NAME_TEXT_SIZE)
				end);
			};

			Blend.New "Frame" {
				Name = "toggleValue";
				BackgroundColor3 = Color3.fromRGB(25, 25, 25);
				BackgroundTransparency = transparency;
				LayoutOrder = 3;

				Size = Blend.Computed(valueWidth, function(width)
					return UDim2.fromOffset(width, VALUE_HEIGHT)
				end);

				Visible = Blend.Computed(self._valueKind, function(kind)
					return kind ~= "none"
				end);

				Blend.New "UICorner" {
					CornerRadius = UDim.new(0, 5);
				};

				Blend.New "UIStroke" {
					Color = Color3.fromRGB(35, 35, 35);
					Transparency = transparency;
				};

				Blend.New "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal;
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
					VerticalAlignment = Enum.VerticalAlignment.Center;
				};

				Blend.New "Frame" {
					Name = "swatch";
					BackgroundColor3 = self._valueColor;
					BackgroundTransparency = transparency;
					LayoutOrder = 1;
					Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE);

					Visible = Blend.Computed(self._valueKind, function(kind)
						return kind == "color"
					end);

					Blend.New "UICorner" {
						CornerRadius = UDim.new(1, 0);
					};

					Blend.New "UIStroke" {
						Color = Color3.fromRGB(85, 85, 85);
						Transparency = transparency;
					};
				};

				Blend.New "TextLabel" {
					Name = "label";
					BackgroundTransparency = 1;
					FontFace = FONT_FACE;
					LayoutOrder = 2;
					Text = self._valueText;
					TextColor3 = Color3.fromRGB(197, 156, 242);
					TextSize = VALUE_TEXT_SIZE;
					TextTransparency = transparency;

					Size = Blend.Computed(valueTextSize, function(size)
						return UDim2.fromOffset(math.ceil(size.X), VALUE_TEXT_SIZE)
					end);

					Visible = Blend.Computed(self._valueKind, function(kind)
						return kind == "text"
					end);
				};
			};
		};
	}
end

return MacroToastEntry
