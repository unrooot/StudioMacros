local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local Rx = require("Rx")
local Signal = require("Signal")
local ValueObject = require("ValueObject")

local ACCENT_COLOR = Color3.fromRGB(197, 156, 242)
local ERROR_COLOR = Color3.fromRGB(180, 84, 86)

local CAPTION_HEIGHT = 14
local CAPTION_PADDING = 4

local NumberInputEntry = setmetatable({}, BasicPane)
NumberInputEntry.ClassName = "NumberInputEntry"
NumberInputEntry.__index = NumberInputEntry

function NumberInputEntry.new()
	local self = setmetatable(BasicPane.new(), NumberInputEntry)

	self._caption = self._maid:Add(ValueObject.new(""))
	self._isValid = self._maid:Add(ValueObject.new(true))
	self._model = self._maid:Add(ButtonHighlightModel.new())
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._placeholder = self._maid:Add(ValueObject.new(""))
	self._preview = self._maid:Add(ValueObject.new(""))

	self.Cancelled = self._maid:Add(Signal.new())
	self.IsFocused = self._maid:Add(ValueObject.new(false))
	self.Submitted = self._maid:Add(Signal.new())
	self.Tabbed = self._maid:Add(Signal.new())
	self.Text = self._maid:Add(ValueObject.new(""))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._model:SetInteractionEnabled(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function NumberInputEntry:SetCaption(caption: string)
	self._caption.Value = caption or ""
end

function NumberInputEntry:SetPlaceholder(placeholder: string)
	self._placeholder.Value = placeholder
end

function NumberInputEntry:SetPreview(preview: string)
	self._preview.Value = preview
end

function NumberInputEntry:SetIsValid(isValid: boolean)
	self._isValid.Value = isValid
end

function NumberInputEntry:SetText(text: string)
	self.Text.Value = text

	if self._input then
		self._input.Text = text
	end
end

function NumberInputEntry:IsInputFocused(): boolean
	return self._input ~= nil and self._input:IsFocused()
end

function NumberInputEntry:Focus()
	local input = self._input
	if not input or not input.Parent then
		return
	end

	input:CaptureFocus()
	input.CursorPosition = #input.Text + 1
end

function NumberInputEntry:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 40, 0.8)
	local percentAlpha = Blend.AccelTween(target, target:Pipe({
		Rx.map(function(value)
			return value == 1 and 400 or 1200
		end)
	}))

	local transparency = Blend.Computed(props.Transparency, percentAlpha, function(parentTransparency, percent)
		return math.clamp(parentTransparency + (1 - percent), 0, 1)
	end)

	local percentFocused = Blend.Spring(Blend.Computed(self.IsFocused, function(isFocused)
		return isFocused and 1 or 0
	end), 35, 0.7)

	local percentHighlighted = Blend.Spring(self._model:ObservePercentHighlightedTarget(), 35, 0.7)

	local percentInvalid = Blend.Spring(Blend.Computed(self._isValid, function(isValid)
		return isValid and 0 or 1
	end), 35, 0.9)

	return Blend.New "Frame" {
		Name = "NumberInputEntry";
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 0, 52);

		Blend.New "Frame" {
			Name = "wrapper";
			BackgroundTransparency = 1;
			Size = UDim2.fromScale(1, 1);

			Position = Blend.Computed(percentVisible, function(percent)
				return UDim2.new(0, 0, 0, (1 - percent) * 6)
			end);

			Blend.New "Frame" {
				Name = "input";
				BackgroundTransparency = transparency;
				Size = UDim2.new(1, 0, 1, -(CAPTION_HEIGHT + CAPTION_PADDING));

				BackgroundColor3 = Blend.Computed(percentHighlighted, percentFocused, function(highlighted, focused)
					return Color3.fromRGB(15, 15, 15):Lerp(Color3.fromRGB(25, 25, 25), math.max(highlighted, focused))
				end);

				Blend.New "UICorner" {
					CornerRadius = UDim.new(0, 5);
				};

				Blend.New "UIStroke" {
					Transparency = transparency;

					Color = Blend.Computed(percentHighlighted, percentFocused, percentInvalid, function(highlighted, focused, invalid)
						return Color3.fromRGB(40, 40, 40)
							:Lerp(Color3.fromRGB(70, 70, 70), highlighted)
							:Lerp(ACCENT_COLOR, focused)
							:Lerp(ERROR_COLOR, invalid)
					end);
				};

				Blend.New "UIPadding" {
					PaddingLeft = UDim.new(0, 10);
					PaddingRight = UDim.new(0, 10);
				};

				Blend.New "TextBox" {
					Name = "input";
					BackgroundTransparency = 1;
					ClearTextOnFocus = false;
					FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
					PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
					PlaceholderText = self._placeholder;
					Size = UDim2.fromScale(1, 1);
					Text = "";
					TextColor3 = Color3.fromRGB(255, 255, 255);
					TextSize = 18;
					TextTransparency = transparency;
					TextXAlignment = Enum.TextXAlignment.Left;
					ZIndex = 5;

					[Blend.Instance] = function(textBox)
						self._input = textBox
						self._model:SetButton(textBox)
					end;

					[Blend.OnChange "Text"] = function(text)
						if not self._input or not string.find(text, "\t", 1, true) then
							self.Text.Value = text
							return
						end

						local stripped = string.gsub(text, "\t", "")

						self._input.Text = stripped
						self._input.CursorPosition = #stripped + 1

						self.Tabbed:Fire()
					end;

					[Blend.OnEvent "Focused"] = function()
						self.IsFocused.Value = true
					end;

					[Blend.OnEvent "FocusLost"] = function(enterPressed, inputObject)
						self.IsFocused.Value = false

						if enterPressed then
							self.Submitted:Fire()
							return
						end

						if inputObject and inputObject.KeyCode == Enum.KeyCode.Escape then
							self.Cancelled:Fire()
						end
					end;
				};

				Blend.New "TextLabel" {
					Name = "preview";
					AnchorPoint = Vector2.new(1, 0.5);
					AutomaticSize = Enum.AutomaticSize.X;
					BackgroundTransparency = 1;
					FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
					Position = UDim2.fromScale(1, 0.5);
					Size = UDim2.fromOffset(0, 14);
					Text = self._preview;
					TextSize = 13;
					TextXAlignment = Enum.TextXAlignment.Right;

					TextColor3 = Blend.Computed(percentFocused, function(percent)
						return Color3.fromRGB(75, 75, 75):Lerp(Color3.fromRGB(110, 110, 110), percent)
					end);

					TextTransparency = Blend.Computed(transparency, self._preview, function(percent, preview)
						return preview == "" and 1 or percent
					end);
				};
			};

			Blend.New "TextLabel" {
				Name = "caption";
				AnchorPoint = Vector2.new(0, 1);
				BackgroundTransparency = 1;
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
				Position = UDim2.fromScale(0, 1);
				Size = UDim2.new(1, 0, 0, CAPTION_HEIGHT);
				Text = self._caption;
				TextSize = 13;
				TextTransparency = transparency;
				TextXAlignment = Enum.TextXAlignment.Left;

				TextColor3 = Blend.Computed(percentFocused, percentInvalid, function(focused, invalid)
					return Color3.fromRGB(90, 90, 90):Lerp(ACCENT_COLOR, focused):Lerp(ERROR_COLOR, invalid)
				end);
			};
		};
	}
end

return NumberInputEntry
