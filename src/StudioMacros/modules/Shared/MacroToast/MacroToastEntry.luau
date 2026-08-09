local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local Rx = require("Rx")
local Signal = require("Signal")
local SpringObject = require("SpringObject")
local ValueObject = require("ValueObject")
local cancellableDelay = require("cancellableDelay")

local DISPLAY_TIME = 1
local FADE_TIME = 0.3
local HORIZONTAL_PADDING = 12

local IMPULSE_PEAK = 0.1
local IMPULSE_VELOCITY = 4

local MacroToastEntry = setmetatable({}, BasicPane)
MacroToastEntry.ClassName = "MacroToastEntry"
MacroToastEntry.Height = 34
MacroToastEntry.__index = MacroToastEntry

function MacroToastEntry.new(macroName: string, groupIcon: string?)
	local self = setmetatable(BasicPane.new(), MacroToastEntry)

	self._groupIcon = self._maid:Add(ValueObject.new(groupIcon or ""))
	self._impulse = self._maid:Add(SpringObject.new(0, 15, 0.9))
	self._macroName = self._maid:Add(ValueObject.new(macroName))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))

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
			return value == 1 and 400 or 2000
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
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = transparency;
			Position = wrapperPosition;
			Size = UDim2.fromOffset(0, MacroToastEntry.Height);

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
				Size = UDim2.fromOffset(15, 15);

				Visible = Blend.Computed(self._groupIcon, function(icon)
					return icon ~= ""
				end);
			};

			Blend.New "TextLabel" {
				Name = "macroName";
				AutomaticSize = Enum.AutomaticSize.X;
				BackgroundTransparency = 1;
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
				LayoutOrder = 2;
				Size = UDim2.fromOffset(0, 15);
				Text = self._macroName;
				TextColor3 = Color3.fromRGB(255, 255, 255);
				TextSize = 15;
				TextTransparency = transparency;
				TextXAlignment = Enum.TextXAlignment.Left;
			};
		};
	}
end

return MacroToastEntry
