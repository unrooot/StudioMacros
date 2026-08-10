local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ChangeSizeEntry = require("ChangeSizeEntry")
local ExpressionUtils = require("ExpressionUtils")
local Rx = require("Rx")
local RxInstanceUtils = require("RxInstanceUtils")
local Signal = require("Signal")
local ValueObject = require("ValueObject")
local getChangeSizeVariables = require("getChangeSizeVariables")

local ACCENT_COLOR = Color3.fromRGB(197, 156, 242)

local AXIS_HEIGHT = 14
local AXIS_PADDING = 6

local DISMISS_ACCEL = 1200
local REVEAL_ACCEL = 400

local FOCUS_ATTEMPTS = 12

local FIELDS = {
	{ Axis = "x"; Caption = "scale"; Key = "XScale" };
	{ Axis = "x"; Caption = "offset"; Key = "XOffset" };
	{ Axis = "y"; Caption = "scale"; Key = "YScale" };
	{ Axis = "y"; Caption = "offset"; Key = "YOffset" };
}

local function formatNumber(value: number): string
	local rounded = math.round(value * 1000) / 1000

	if rounded == math.round(rounded) then
		return string.format("%.0f", rounded)
	end

	return (string.gsub(string.format("%.3f", rounded), "0+$", ""))
end

local ChangeSizePane = setmetatable({}, BasicPane)
ChangeSizePane.ClassName = "ChangeSizePane"
ChangeSizePane.__index = ChangeSizePane

function ChangeSizePane.new()
	local self = setmetatable(BasicPane.new(), ChangeSizePane)

	self._entries = {}
	self._focusAttempt = 0
	self._focusedIndex = self._maid:Add(ValueObject.new(0))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._target = self._maid:Add(ValueObject.new(nil))
	self._targetSize = self._maid:Add(ValueObject.new(Vector2.zero))
	self._targetUDim = self._maid:Add(ValueObject.new(UDim2.new()))

	self.Cancelled = self._maid:Add(Signal.new())
	self.Submitted = self._maid:Add(Signal.new())

	self:_createEntries()

	self._maid:GiveTask(self._target:ObserveBrio():Subscribe(function(targetBrio)
		if targetBrio:IsDead() then
			return
		end

		local maid, target = targetBrio:ToMaidAndValue()
		if not target then
			return
		end

		maid:GiveTask(RxInstanceUtils.observeProperty(target, "Size"):Subscribe(function(size)
			self._targetUDim.Value = size

			self._entries[1]:SetPlaceholder(formatNumber(size.X.Scale))
			self._entries[2]:SetPlaceholder(formatNumber(size.X.Offset))
			self._entries[3]:SetPlaceholder(formatNumber(size.Y.Scale))
			self._entries[4]:SetPlaceholder(formatNumber(size.Y.Offset))
		end))

		maid:GiveTask(RxInstanceUtils.observeProperty(target, "AbsoluteSize"):Subscribe(function(absoluteSize)
			self._targetSize.Value = absoluteSize
		end))
	end))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function ChangeSizePane.getFieldNames(): { string }
	local names = {}

	for _, field in FIELDS do
		table.insert(names, `{field.Axis}.{field.Caption}`)
	end

	return names
end

function ChangeSizePane:SetTarget(target: GuiObject?)
	self._target.Value = target
end

function ChangeSizePane:CaptureFocus(index: number?)
	local targetIndex = index or 1

	local entry = self._entries[targetIndex]
	if not entry then
		return
	end

	self._focusAttempt += 1

	local attempt = self._focusAttempt
	local originIndex = self:_getFocusedIndex()

	task.spawn(function()
		for _ = 1, FOCUS_ATTEMPTS do
			if attempt ~= self._focusAttempt then
				return
			end

			local focusedIndex = self:_getFocusedIndex()
			if focusedIndex == targetIndex then
				return
			end

			if focusedIndex ~= 0 and focusedIndex ~= originIndex then
				return
			end

			entry:Focus()

			RunService.RenderStepped:Wait()
		end

		if attempt == self._focusAttempt and not entry:IsInputFocused() then
			warn(`[ChangeSize] focus never landed on field {targetIndex} after {FOCUS_ATTEMPTS} frames`)
		end
	end)
end

function ChangeSizePane:FlagField(key: string)
	for index, field in FIELDS do
		if field.Key == key then
			self._entries[index]:SetIsValid(false)
			self:CaptureFocus(index)
			return
		end
	end
end

function ChangeSizePane:ParkFocus()
	local keySink = self._keySink
	if not keySink or not keySink.Parent then
		return
	end

	self._focusAttempt += 1
	self._isParked = true

	local attempt = self._focusAttempt

	task.spawn(function()
		for _ = 1, FOCUS_ATTEMPTS do
			if attempt ~= self._focusAttempt or not self._isParked or keySink:IsFocused() then
				return
			end

			keySink.Text = ""
			keySink:CaptureFocus()

			RunService.RenderStepped:Wait()
		end
	end)
end

function ChangeSizePane:Reset()
	self._focusAttempt += 1
	self._isParked = false
	self._focusedIndex.Value = 0

	for _, entry in self._entries do
		entry.IsFocused.Value = false
		entry:SetText("")
	end
end

function ChangeSizePane:_getFocusedIndex(): number
	for index, entry in self._entries do
		if entry:IsInputFocused() then
			return index
		end
	end

	return 0
end

function ChangeSizePane:Submit()
	local values = {}

	for index, field in FIELDS do
		values[field.Key] = self._entries[index].Text.Value
	end

	self.Submitted:Fire(values)
end

function ChangeSizePane:_createEntries()
	for index, field in FIELDS do
		local entry = self._maid:Add(ChangeSizeEntry.new(field.Caption))
		entry:SetLayoutOrder(index)

		self._maid:GiveTask(entry.Tabbed:Connect(function()
			self:CaptureFocus((index % #FIELDS) + 1)
		end))

		self._maid:GiveTask(entry.Submitted:Connect(function()
			self:Submit()
		end))

		self._maid:GiveTask(entry.Cancelled:Connect(function()
			self:ParkFocus()
		end))

		self._maid:GiveTask(entry.IsFocused:Observe():Subscribe(function(isFocused)
			if isFocused then
				self._focusedIndex.Value = index
			elseif self._focusedIndex.Value == index then
				self._focusedIndex.Value = 0
			end
		end))

		self._maid:GiveTask(Blend.Computed(entry.Text, self._targetSize, self._targetUDim, function(text, absoluteSize, size)
			if text == "" then
				return { IsValid = true; Preview = "" }
			end

			local value = ExpressionUtils.evaluate(text, getChangeSizeVariables(absoluteSize, size))
			if not value then
				return { IsValid = false; Preview = "" }
			end

			local formatted = formatNumber(value)

			return { IsValid = true; Preview = formatted ~= text and formatted or "" }
		end):Subscribe(function(state)
			entry:SetIsValid(state.IsValid)
			entry:SetPreview(state.Preview)
		end))

		table.insert(self._entries, entry)
	end
end

function ChangeSizePane:_renderAxis(axis: string, startIndex: number, transparency)
	local percentFocused = Blend.Spring(Blend.Computed(self._focusedIndex, function(index)
		return (index == startIndex or index == startIndex + 1) and 1 or 0
	end), 35, 0.7)

	return Blend.New "Frame" {
		Name = axis;
		BackgroundTransparency = 1;
		LayoutOrder = startIndex;
		Size = UDim2.fromScale(0.5, 1);

		Blend.New "TextLabel" {
			Name = "axis";
			BackgroundTransparency = 1;
			FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
			Size = UDim2.new(1, 0, 0, AXIS_HEIGHT);
			Text = axis;
			TextSize = 14;
			TextTransparency = transparency;
			TextXAlignment = Enum.TextXAlignment.Left;

			TextColor3 = Blend.Computed(percentFocused, function(percent)
				return Color3.fromRGB(90, 90, 90):Lerp(ACCENT_COLOR, percent)
			end);
		};

		Blend.New "Frame" {
			Name = "fields";
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, AXIS_HEIGHT + AXIS_PADDING);
			Size = UDim2.new(1, 0, 1, -(AXIS_HEIGHT + AXIS_PADDING));

			Blend.New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalFlex = Enum.UIFlexAlignment.Fill;
				Padding = UDim.new(0, 8);
				SortOrder = Enum.SortOrder.LayoutOrder;
				VerticalAlignment = Enum.VerticalAlignment.Center;
			};

			self._entries[startIndex]:Render({ Transparency = transparency });
			self._entries[startIndex + 1]:Render({ Transparency = transparency });
		};
	}
end

function ChangeSizePane:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 40, 0.8)
	local percentAlpha = Blend.AccelTween(target, target:Pipe({
		Rx.map(function(value)
			return value == 1 and REVEAL_ACCEL or DISMISS_ACCEL
		end)
	}))

	local transparency = Blend.Computed(percentAlpha, function(percent)
		return 1 - percent
	end)

	self._maid:GiveTask(Blend.Computed(percentAlpha, function(percent)
		local count = math.max(1, #self._entries)

		for index, entry in self._entries do
			entry:SetVisible((index - 1) / count + 1e-1 <= percent)
		end
	end):Subscribe())

	return Blend.New "Frame" {
		Name = "ChangeSizePane";
		BackgroundColor3 = Color3.fromRGB(30, 30, 30);
		BackgroundTransparency = transparency;
		Parent = props and props.Parent;
		Size = UDim2.fromScale(1, 1);

		Visible = Blend.Computed(percentAlpha, function(percent)
			return percent > 0.001
		end);

		Blend.New "UIPadding" {
			PaddingBottom = UDim.new(0, 14);
			PaddingLeft = UDim.new(0, 14);
			PaddingRight = UDim.new(0, 14);
			PaddingTop = UDim.new(0, 14);
		};

		Blend.New "TextBox" {
			Name = "keySink";
			BackgroundTransparency = 1;
			ClearTextOnFocus = false;
			Size = UDim2.fromOffset(1, 1);
			Text = "";
			TextSize = 8;
			TextTransparency = 1;
			ZIndex = 0;

			[Blend.Instance] = function(textBox)
				self._keySink = textBox
			end;

			[Blend.OnChange "Text"] = function(text)
				if text == "" or not self._keySink then
					return
				end

				local isTab = string.find(text, "\t", 1, true) ~= nil
				self._keySink.Text = ""

				if isTab then
					self:CaptureFocus(1)
				end
			end;

			[Blend.OnEvent "FocusLost"] = function(_enterPressed, inputObject)
				local wasParked = self._isParked
				self._isParked = false

				if wasParked and inputObject and inputObject.KeyCode == Enum.KeyCode.Escape then
					self.Cancelled:Fire()
				end
			end;
		};

		Blend.New "Frame" {
			Name = "wrapper";
			BackgroundTransparency = 1;
			Size = UDim2.fromScale(1, 1);

			Position = Blend.Computed(percentVisible, function(percent)
				return UDim2.new(0, 0, 0, (1 - percent) * 8)
			end);

			Blend.New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalFlex = Enum.UIFlexAlignment.Fill;
				Padding = UDim.new(0, 16);
				SortOrder = Enum.SortOrder.LayoutOrder;
				VerticalAlignment = Enum.VerticalAlignment.Center;
			};

			self:_renderAxis("x", 1, transparency);
			self:_renderAxis("y", 3, transparency);
		};
	}
end

return ChangeSizePane
