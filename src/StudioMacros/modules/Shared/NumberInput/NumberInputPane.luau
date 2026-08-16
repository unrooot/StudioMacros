local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local NumberInputEntry = require("NumberInputEntry")
local Rx = require("Rx")
local Signal = require("Signal")
local ValueObject = require("ValueObject")
local formatNumber = require("formatNumber")

local FOCUS_HOLD_FRAMES = 3
local FOCUS_TIMEOUT = 1.5

--[=[
	A single-field number input, styled to match the rest of the palette. The
	pane owns nothing but the field: the evaluator that turns typed text into a
	number is supplied by whoever drives it, so the same pane can back any macro
	that asks for one number.

	@class NumberInputPane
]=]
local NumberInputPane = setmetatable({}, BasicPane)
NumberInputPane.ClassName = "NumberInputPane"
NumberInputPane.__index = NumberInputPane

function NumberInputPane.new()
	local self = setmetatable(BasicPane.new(), NumberInputPane)

	self._entry = self._maid:Add(NumberInputEntry.new())
	self._evaluator = self._maid:Add(ValueObject.new(nil))
	self._focusAttempt = 0
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))

	self.Cancelled = self._maid:Add(Signal.new())
	self.Submitted = self._maid:Add(Signal.new())

	self._maid:GiveTask(self._entry.Tabbed:Connect(function()
		self:CaptureFocus()
	end))

	self._maid:GiveTask(self._entry.Submitted:Connect(function()
		self.Submitted:Fire(self._entry.Text.Value)
	end))

	self._maid:GiveTask(self._entry.Cancelled:Connect(function()
		self:ParkFocus()
	end))

	self._maid:GiveTask(Blend.Computed(self._entry.Text, self._evaluator, function(text, evaluator)
		if text == "" or not evaluator then
			return { IsValid = true; Preview = "" }
		end

		local value = evaluator(text)
		if not value then
			return { IsValid = false; Preview = "" }
		end

		local formatted = formatNumber(value)

		return { IsValid = true; Preview = formatted ~= text and formatted or "" }
	end):Subscribe(function(state)
		self._entry:SetIsValid(state.IsValid)
		self._entry:SetPreview(state.Preview)
	end))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
		self._entry:SetVisible(isVisible)
	end))

	return self
end

function NumberInputPane:SetCaption(caption: string)
	self._entry:SetCaption(caption)
end

function NumberInputPane:SetPlaceholder(placeholder: string)
	self._entry:SetPlaceholder(placeholder)
end

--[=[
	Sets the function used to preview typed text. It should return a number, or
	nil when the text can't be read as one.

	@param evaluator ((text: string) -> number?)?
]=]
function NumberInputPane:SetEvaluator(evaluator)
	self._evaluator.Value = evaluator
end

function NumberInputPane:CaptureFocus()
	local entry = self._entry

	self._focusAttempt += 1
	self._isParked = false

	local attempt = self._focusAttempt

	task.spawn(function()
		local deadline = os.clock() + FOCUS_TIMEOUT
		local heldFrames = 0

		while os.clock() < deadline do
			if attempt ~= self._focusAttempt then
				return
			end

			if entry:IsInputFocused() then
				heldFrames += 1

				if heldFrames >= FOCUS_HOLD_FRAMES then
					return
				end
			else
				heldFrames = 0
				entry:Focus()
			end

			RunService.RenderStepped:Wait()
		end

		if attempt == self._focusAttempt and not entry:IsInputFocused() then
			warn("[StudioMacros]: Number input focus never landed")
		end
	end)
end

--[=[
	Moves focus onto the invisible sink behind the field, so a second escape
	closes the window instead of handing focus back to Studio.
]=]
function NumberInputPane:ParkFocus()
	local keySink = self._keySink
	if not keySink or not keySink.Parent then
		return
	end

	self._focusAttempt += 1
	self._isParked = true

	local attempt = self._focusAttempt

	task.spawn(function()
		for _ = 1, 12 do
			if attempt ~= self._focusAttempt or not self._isParked or keySink:IsFocused() then
				return
			end

			keySink.Text = ""
			keySink:CaptureFocus()

			RunService.RenderStepped:Wait()
		end
	end)
end

function NumberInputPane:FlagField()
	self._entry:SetIsValid(false)
	self:CaptureFocus()
end

function NumberInputPane:Reset()
	self._focusAttempt += 1
	self._isParked = false

	self._entry.IsFocused.Value = false
	self._entry:SetText("")
	self._entry:SetIsValid(true)
end

function NumberInputPane:IsFieldFocused(): boolean
	return self._entry:IsInputFocused()
end

function NumberInputPane:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 40, 0.8)
	local percentAlpha = Blend.AccelTween(target, target:Pipe({
		Rx.map(function(value)
			return value == 1 and 400 or 1200
		end)
	}))

	local transparency = Blend.Computed(percentAlpha, function(percent)
		return 1 - percent
	end)

	return Blend.New "Frame" {
		Name = "NumberInputPane";
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
					self:CaptureFocus()
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
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				VerticalAlignment = Enum.VerticalAlignment.Center;
			};

			self._entry:Render({ Transparency = transparency });
		};
	}
end

return NumberInputPane
