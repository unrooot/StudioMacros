local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local Rx = require("Rx")
local SearchUtils = require("SearchUtils")
local Signal = require("Signal")
local SpringObject = require("SpringObject")
local ValueObject = require("ValueObject")

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local ColorPickerPane = setmetatable({}, BasicPane)
ColorPickerPane.ClassName = "ColorPickerPane"
ColorPickerPane.CustomResultType = "Color"
ColorPickerPane.Height = 160
ColorPickerPane.Pinned = true
ColorPickerPane.__index = ColorPickerPane

function ColorPickerPane.new()
	local self = setmetatable(BasicPane.new(), ColorPickerPane)

	self._tabInputMap = {}

	self._currentBrightness = self._maid:Add(ValueObject.new(nil))
	self._currentHue = self._maid:Add(ValueObject.new(nil))
	self._currentSaturation = self._maid:Add(ValueObject.new(nil))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._tabInputIndex = self._maid:Add(ValueObject.new(nil))
	self._targetParent = self._maid:Add(ValueObject.new(nil))
	self._yPosition = self._maid:Add(ValueObject.new(0))

	self.ColorUpdated = self._maid:Add(Signal.new())
	self.CurrentColor = self._maid:Add(ValueObject.new(Color3.new(1, 1, 1)))
	self.TabReturned = self._maid:Add(Signal.new())

	self._maid:GiveTask(self._tabInputIndex:Observe():Subscribe(function(index)
		if not index then
			return
		end

		if index == 0 then
			self.TabReturned:Fire()
			return
		end

		local input = self._tabInputMap[index]
		if input then
			task.spawn(function()
				RunService.RenderStepped:Wait()
				input:CaptureFocus()
			end)
		end
	end))

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local shiftPressed = self:_shiftPressed()

			if input.KeyCode == Enum.KeyCode.Tab then
				if shiftPressed then
					self._tabInputIndex.Value = math.clamp(self._tabInputIndex.Value - 1, 0, #self._tabInputMap)
				end
			end
		end
	end))

	self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not self:IsVisible() then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if self.DraggingHue then
				self:_updateHuePosition(input)
			elseif self.DraggingBrightness then
				self:_updateBrightnessPosition(input)
			elseif self.DraggingCursor then
				self:_updateCursorPosition(input)
			end
		end
	end))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function ColorPickerPane:ObserveColor()
	return self.CurrentColor:Observe()
end

function ColorPickerPane:SetColor(color)
	self.CurrentColor.Value = color
end

function ColorPickerPane:GetYPosition()
	return self._yPosition.Value
end

function ColorPickerPane:_updateCursorPosition(inputObject)
	if not self._color then
		return
	end

	local relativeX = inputObject.Position.X - self._color.AbsolutePosition.X
	local relativeY = inputObject.Position.Y - self._color.AbsolutePosition.Y

	local saturation = math.abs(math.clamp(relativeX / self._color.AbsoluteSize.X, 0, 1) - 1)
	local value = math.abs(math.clamp(relativeY / self._color.AbsoluteSize.Y, 0, 1) - 1)

	self._currentSaturation.Value = saturation
	self._currentBrightness.Value = value
end

function ColorPickerPane:_updateHuePosition(inputObject)
	if not self._hue then
		return
	end

	local relativeY = inputObject.Position.Y - self._hue.AbsolutePosition.Y
	local hue = math.clamp(relativeY / self._hue.AbsoluteSize.Y, 0, 1)

	self._currentHue.Value = hue
end

function ColorPickerPane:_updateBrightnessPosition(inputObject)
	if not self._brightness then
		return
	end

	local relativeY = inputObject.Position.Y - self._brightness.AbsolutePosition.Y
	local value = math.clamp(relativeY / self._brightness.AbsoluteSize.Y, 0, 1)

	self._currentBrightness.Value = math.abs(1 - value)
end

function ColorPickerPane:SetTargetParent(targetParent)
	self._targetParent.Value = targetParent
end

function ColorPickerPane:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 30, 0.7)
	local transparency = props.Transparency

	local hue = self._maid:Add(Blend.State(0))

	local oldColor = self._maid:Add(Blend.State(self.CurrentColor.Value))
	local targetColor = self._maid:Add(Instance.new("Color3Value"))

	self._maid:GiveTask(Blend.Computed(self._currentHue, self._currentSaturation, self._currentBrightness, function(hue, saturation, brightness)
		if not hue or not saturation or not brightness then
			local currentColor = self.CurrentColor.Value
			if not currentColor then
				return
			end

			hue, saturation, brightness = currentColor:ToHSV()
		end

		self.CurrentColor.Value = Color3.fromHSV(hue, saturation, brightness)
	end):Subscribe())

	self._maid:GiveTask(self.CurrentColor:Observe():Subscribe(function(newColor)
		if not newColor then
			return
		end

		local h, s, v = newColor:ToHSV()
		-- Fill default hsv values
		local currentHue = self._currentHue.Value
		if not currentHue or h ~= self._currentHue.Value then
			self._currentHue.Value = h
		end
		local currentSaturation = self._currentSaturation.Value
		if not currentSaturation or s ~= self._currentSaturation.Value then
			self._currentSaturation.Value = s
		end
		local currentBrightness = self._currentBrightness.Value
		if not currentBrightness or v ~= self._currentBrightness.Value then
			self._currentBrightness.Value = v
		end

		TweenService:Create(targetColor, TWEEN_INFO, {
			Value = newColor
		}):Play()

		oldColor.Value = newColor
	end))

	local percentHue = Blend.Spring(self._currentHue, 35, 0.9)
	local percentSaturation = Blend.Spring(self._currentSaturation, 35, 0.9)
	local percentBrightness = Blend.Spring(self._currentBrightness, 35, 0.9)

	local pickerCursorX = Blend.Spring(percentSaturation:Pipe({
		Rx.map(function(percent)
			return math.abs(percent - 1)
		end);
	}), 50, 0.9)

	local pickerCursorY = Blend.Spring(percentBrightness:Pipe({
		Rx.map(function(percent)
			return math.abs(percent - 1)
		end);
	}), 50, 0.9)

	self._maid._tabbed = props.Tabbed:Connect(function()
		if self:_shiftPressed() then
			return
		end

		if not self._tabInputIndex.Value then
			self._tabInputIndex.Value = 1
			return
		end

		self._tabInputIndex.Value = math.clamp(self._tabInputIndex.Value + 1, 0, #self._tabInputMap)
	end)

	return Blend.New "Frame" {
		Name = "ColorPickerPane";
		BackgroundTransparency = 1;
		LayoutOrder = -1;
		LayoutOrder = -9e9;
		Size = UDim2.new(1, 0, 0, self.Height);
		Parent = self._targetParent;

		Visible = Blend.Computed(props.CustomResult, props.Enabled, function(customResult, isEnabled)
			if customResult then
				return isEnabled
			else
				return false
			end
		end);

		[Blend.OnChange "AbsolutePosition"] = function(position)
			if not self:IsVisible() then
				return
			end

			self._yPosition.Value = math.round(position.Y)
		end;

		Blend.New "Frame" {
			Name = "wrapper";
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 1, -10);

			Blend.New "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Center;
				HorizontalFlex = Enum.UIFlexAlignment.Fill;
				Padding = UDim.new(0, 6);
				VerticalAlignment = Enum.VerticalAlignment.Center;
			};

			Blend.New "Frame" {
				Name = "currentColor";
				BackgroundColor3 = targetColor;
				BackgroundTransparency = transparency;
				LayoutOrder = 1;
				Size = UDim2.new(0, 40, 1, 0);

				Blend.New "UIFlexItem" { };

				Blend.New "UICorner" {
					CornerRadius = UDim.new(0, 5);
				};

				Blend.New "UIStroke" {
					Color = Color3.fromRGB(40, 40, 40);
					Transparency = transparency;
				};
			};

			Blend.New "Frame" {
				Name = "selection";
				BackgroundTransparency = 1;
				LayoutOrder = 2;
				Size = UDim2.fromScale(0.5, 1);
				ZIndex = 3;

				Blend.New "Frame" {
					Name = "background";
					BackgroundTransparency = 1;
					Size = UDim2.fromScale(1, 1);

					Blend.New "Frame" {
						Name = "white";
						BackgroundTransparency = transparency;
						Size = UDim2.fromScale(1, 1);
						ZIndex = 2;

						Blend.New "UIGradient" {
							Transparency = NumberSequence.new(1, 0);
						};

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
						};
					};

					Blend.New "Frame" {
						Name = "black";
						BackgroundTransparency = transparency;
						Size = UDim2.fromScale(1, 1);
						ZIndex = 3;

						Blend.New "UIGradient" {
							Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0));
							Rotation = 90;
							Transparency = NumberSequence.new(1, 0);
						};

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 4);
						};

						Blend.New "UIStroke" {
							Color = Color3.fromRGB(40, 40, 40);
							Transparency = transparency;
						};
					};

					Blend.New "Frame" {
						Name = "color";
						BackgroundColor3 = targetColor;
						BackgroundTransparency = props.Transparency;
						Size = UDim2.fromScale(1, 1);

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
						};
					};
				};

				Blend.New "TextButton" {
					Name = "button";
					Size = UDim2.fromScale(1, 1);
					BackgroundColor3 = Color3.fromRGB(163, 162, 165);
					BackgroundTransparency = 1;
					TextColor3 = Color3.fromRGB(27, 42, 53);
					TextSize = 8;
					ZIndex = 5;

					[Blend.Instance] = function(instance)
						self._color = instance
					end;

					[Blend.OnEvent "InputBegan"] = function(input)
						if self:_isValidInput(input) then
							self.DraggingCursor = true
							self:_updateCursorPosition(input)
						end
					end;

					[Blend.OnEvent "InputEnded"] = function(input)
						if self:_isValidInput(input) then
							self.DraggingCursor = false
							self.ColorUpdated:Fire(self.CurrentColor.Value)
						end
					end;
				};

				Blend.New "Frame" {
					Name = "cursor";
					AnchorPoint = Vector2.new(0.5, 0.5);
					BackgroundTransparency = 1;
					Size = UDim2.fromScale(0.1, 0.1);
					ZIndex = 5;

					Position = Blend.Computed(pickerCursorX, pickerCursorY, function(x, y)
						return UDim2.fromScale(x, y);
					end);

					Blend.New "UIAspectRatioConstraint" {
						AspectRatio = 1;
					};

					Blend.New "UISizeConstraint" {
						MaxSize = Vector2.new(16, 16);
					};

					Blend.New "Frame" {
						Name = "container";
						AnchorPoint = Vector2.new(0.5, 0.5);
						BackgroundTransparency = 1;
						Position = UDim2.fromScale(0.5, 0.5);
						Size = UDim2.fromScale(1, 1);

						Blend.New "Frame" {
							Name = "dot";
							AnchorPoint = Vector2.new(0.5, 0.5);
							BackgroundTransparency = 1;
							Position = UDim2.fromScale(0.5, 0.5);
							Size = UDim2.fromScale(1, 1);

							Blend.New "UICorner" {
								CornerRadius = UDim.new(1, 0);
							};

							Blend.New "UIPadding" {
								PaddingBottom = UDim.new(0, 2);
								PaddingLeft = UDim.new(0, 2);
								PaddingRight = UDim.new(0, 2);
								PaddingTop = UDim.new(0, 2);
							};

							Blend.New "UIStroke" {
								Color = Color3.fromRGB(255, 255, 255);
								Transparency = transparency;
							};

							Blend.New "Frame" {
								Name = "inner";
								AnchorPoint = Vector2.new(0.5, 0.5);
								BackgroundTransparency = transparency;
								Position = UDim2.fromScale(0.5, 0.5);
								Size = UDim2.fromScale(1, 1);

								Blend.New "UICorner" {
									CornerRadius = UDim.new(1, 0);
								};
							};
						};

						Blend.New "ImageLabel" {
							Name = "shadow";
							Position = UDim2.fromScale(0.5, 0.5);
							AnchorPoint = Vector2.new(0.5, 0.5);
							Size = UDim2.fromScale(2, 2);
							BackgroundColor3 = Color3.fromRGB(163, 162, 165);
							BackgroundTransparency = 1;
							Image = "rbxassetid://6150493168";
							ImageColor3 = Color3.fromRGB(0, 0, 0);
							ImageTransparency = 0.8;
							ZIndex = -10;
						};
					};
				};
			};

			Blend.New "Frame" {
				Name = "sliders";
				BackgroundTransparency = 1;
				LayoutOrder = 3;
				Position = UDim2.fromScale(0.5, 0);
				Size = UDim2.new(0, 40, 1, 0);
				ZIndex = 2;

				Blend.New "UIFlexItem" { };

				Blend.New "Frame" {
					Name = "hue";
					AnchorPoint = Vector2.new(0, 1);
					BackgroundTransparency = 1;
					Position = UDim2.fromScale(0, 1);
					Size = UDim2.new(0, 16, 1, 0);

					Blend.New "Frame" {
						Name = "container";
						BackgroundTransparency = transparency;
						Size = UDim2.fromScale(1, 1);
						ZIndex = 2;

						Blend.New "UIStroke" {
							Color = Color3.fromRGB(40, 40, 40);
							Transparency = transparency;
						};

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 3);
						};

						Blend.New "UIGradient" {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
								ColorSequenceKeypoint.new(0.05571, Color3.fromRGB(255, 85, 0)),
								ColorSequenceKeypoint.new(0.111421, Color3.fromRGB(255, 170, 0)),
								ColorSequenceKeypoint.new(0.167131, Color3.fromRGB(254, 255, 0)),
								ColorSequenceKeypoint.new(0.222841, Color3.fromRGB(169, 255, 0)),
								ColorSequenceKeypoint.new(0.278552, Color3.fromRGB(83, 255, 0)),
								ColorSequenceKeypoint.new(0.334262, Color3.fromRGB(0, 255, 1)),
								ColorSequenceKeypoint.new(0.389972, Color3.fromRGB(0, 255, 86)),
								ColorSequenceKeypoint.new(0.445682, Color3.fromRGB(0, 255, 171)),
								ColorSequenceKeypoint.new(0.501393, Color3.fromRGB(0, 252, 255)),
								ColorSequenceKeypoint.new(0.557103, Color3.fromRGB(0, 167, 255)),
								ColorSequenceKeypoint.new(0.612813, Color3.fromRGB(0, 82, 255)),
								ColorSequenceKeypoint.new(0.668524, Color3.fromRGB(2, 0, 255)),
								ColorSequenceKeypoint.new(0.724234, Color3.fromRGB(88, 0, 255)),
								ColorSequenceKeypoint.new(0.779944, Color3.fromRGB(173, 0, 255)),
								ColorSequenceKeypoint.new(0.835655, Color3.fromRGB(255, 0, 251)),
								ColorSequenceKeypoint.new(0.891365, Color3.fromRGB(255, 0, 166)),
								ColorSequenceKeypoint.new(0.947075, Color3.fromRGB(255, 0, 80)),
								ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
							});
							Rotation = 90;
						};

						Blend.New "Frame" {
							Name = "cursor";
							AnchorPoint = Vector2.new(0.5, 0.5);
							BackgroundTransparency = transparency;
							Size = UDim2.fromScale(1.2, 1);

							Position = Blend.Computed(percentHue, function(percent)
								return UDim2.fromScale(0.5, percent)
							end);

							Blend.New "UIAspectRatioConstraint" {
								AspectRatio = 2.5;
							};

							Blend.New "UICorner" {
								CornerRadius = UDim.new(0, 2);
							};

							Blend.New "UIStroke" {
								Color = Color3.fromRGB(230, 230, 230);
								Transparency = transparency;
							};
						};
					};

					Blend.New "TextButton" {
						Name = "button";
						Size = UDim2.fromScale(1, 1);
						BackgroundColor3 = Color3.fromRGB(163, 162, 165);
						BackgroundTransparency = 1;
						TextColor3 = Color3.fromRGB(27, 42, 53);
						TextSize = 8;
						ZIndex = 5;

						[Blend.Instance] = function(instance)
							self._hue = instance
						end;

						[Blend.OnEvent "InputBegan"] = function(input)
							if self:_isValidInput(input) then
								self.DraggingHue = true
								self:_updateHuePosition(input)
							end
						end;

						[Blend.OnEvent "InputEnded"] = function(input)
							if self:_isValidInput(input) then
								self.DraggingHue = false
								self.ColorUpdated:Fire(self.CurrentColor.Value)
							end
						end;
					};
				};

				Blend.New "Frame" {
					Name = "brightness";
					Position = UDim2.fromScale(1, 1);
					AnchorPoint = Vector2.new(1, 1);
					Size = UDim2.new(0, 16, 1, 0);
					BackgroundTransparency = 1;

					Blend.New "Frame" {
						Name = "container";
						BackgroundTransparency = transparency;
						Size = UDim2.fromScale(1, 1);
						ZIndex = 2;

						Blend.New "UIStroke" {
							Color = Color3.fromRGB(40, 40, 40);
							Transparency = transparency;
						};

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 3);
						};

						Blend.New "UIGradient" {
							Rotation = 90;

							Color = Blend.Computed(targetColor, function(color)
								return ColorSequence.new(color, Color3.fromRGB(0, 0, 0));
							end);
						};

						Blend.New "Frame" {
							Name = "cursor";
							AnchorPoint = Vector2.new(0.5, 0.5);
							BackgroundTransparency = transparency;
							Size = UDim2.fromScale(1.2, 1);

							Position = Blend.Computed(percentBrightness, function(percent)
								return UDim2.fromScale(0.5, 1 - percent)
							end);

							Blend.New "UIAspectRatioConstraint" {
								AspectRatio = 2.5;
							};

							Blend.New "UICorner" {
								CornerRadius = UDim.new(0, 2);
							};

							Blend.New "UIStroke" {
								Color = Color3.fromRGB(230, 230, 230);
								Transparency = transparency;
							};
						};
					};

					Blend.New "TextButton" {
						Name = "button";
						Size = UDim2.fromScale(1, 1);
						BackgroundColor3 = Color3.fromRGB(163, 162, 165);
						BackgroundTransparency = 1;
						TextColor3 = Color3.fromRGB(27, 42, 53);
						TextSize = 8;
						ZIndex = 5;

						[Blend.Instance] = function(instance)
							self._brightness = instance
						end;

						[Blend.OnEvent "InputBegan"] = function(input)
							if self:_isValidInput(input) then
								self.DraggingBrightness = true
								self:_updateBrightnessPosition(input)
							end
						end;

						[Blend.OnEvent "InputEnded"] = function(input)
							if self:_isValidInput(input) then
								self.DraggingBrightness = false
								self.ColorUpdated:Fire(self.CurrentColor.Value)
							end
						end;
					};
				};
			};

			Blend.New "Frame" {
				Name = "inputs";
				BackgroundTransparency = 1;
				LayoutOrder = 4;
				Position = UDim2.fromScale(0.780371, 0);
				Size = UDim2.fromScale(0.2, 1);
				ZIndex = 2;

				Blend.New "UIListLayout" {
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
					Padding = UDim.new(0, 5);
					VerticalAlignment = Enum.VerticalAlignment.Center;
					VerticalFlex = Enum.UIFlexAlignment.Fill;
				};

				Blend.New "Frame" {
					Name = "rgb";
					BackgroundColor3 = Color3.fromRGB(15, 15, 15);
					BackgroundTransparency = transparency;
					LayoutOrder = 1;
					Size = UDim2.fromScale(1, 1);

					Blend.New "UICorner" {
						CornerRadius = UDim.new(0, 5);
					};

					Blend.New "UIStroke" {
						Color = Color3.fromRGB(40, 40, 40);
						Transparency = transparency;
					};

					Blend.New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal;
						HorizontalAlignment = Enum.HorizontalAlignment.Center;
						HorizontalFlex = Enum.UIFlexAlignment.Fill;
						Padding = UDim.new(0, 5);
						VerticalAlignment = Enum.VerticalAlignment.Center;
					};

					Blend.New "UIPadding" {
						PaddingBottom = UDim.new(0, 10);
						PaddingLeft = UDim.new(0, 10);
						PaddingRight = UDim.new(0, 10);
						PaddingTop = UDim.new(0, 10);
					};

					Blend.New "ImageLabel" {
						Name = "icon";
						LayoutOrder = 1;
						Size = UDim2.fromScale(1, 1);
						BackgroundTransparency = 1;
						Image = "rbxassetid://6034316009";
						ImageColor3 = Color3.fromRGB(75, 75, 75);

						Blend.New "UIAspectRatioConstraint" {
							AspectRatio = 1;
						};
					};

					Blend.New "TextBox" {
						Name = "input";
						LayoutOrder = 2;
						Size = UDim2.fromScale(1, 1);
						BackgroundColor3 = Color3.fromRGB(163, 162, 165);
						BackgroundTransparency = 1;
						FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
						PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
						TextColor3 = Color3.fromRGB(255, 255, 255);
						TextSize = 18;
						TextXAlignment = Enum.TextXAlignment.Left;
						ZIndex = 5;

						PlaceholderText = Blend.Computed(targetColor, function(color)
							return `{math.round(color.R * 255)}, {math.round(color.G * 255)}, {math.round(color.B * 255)}`
						end);

						[Blend.Instance] = function(textBox)
							self._rgbInput = textBox
							table.insert(self._tabInputMap, 1, textBox)
						end;

						[Blend.OnChange "Text"] = function(newText)
							if not self._rgbInput then
								return
							end

							if newText == self._rgbInput.PlaceholderText then
								return
							end

							if SearchUtils.stringIsRGB(self._rgbInput.Text) then
								local _, r, g, b = SearchUtils.stringIsRGB(self._rgbInput.Text)
								self:SetColor(Color3.fromRGB(r, g, b))
							end
						end;

						[Blend.OnEvent "Focused"] = function()
							self:_handleFocused(self._rgbInput)
						end;

						[Blend.OnEvent "FocusLost"] = function(enterPressed)
							if not self._rgbInput then
								return
							end

							if enterPressed then
								if self._rgbInput.Text ~= self._rgbInput.PlaceholderText then
									if SearchUtils.stringIsRGB(self._rgbInput.Text) then
										local _, r, g, b = SearchUtils.stringIsRGB(self._rgbInput.Text)
										self:SetColor(Color3.fromRGB(r, g, b))
									end

									self._rgbInput.Text = ""
								else
									self._rgbInput.Text = ""
								end
							else
								self._rgbInput.Text = ""
							end
						end;

						self:_handleFocusLost()
					};
				};

				Blend.New "Frame" {
					Name = "hex";
					BackgroundColor3 = Color3.fromRGB(15, 15, 15);
					BackgroundTransparency = transparency;
					LayoutOrder = 2;
					Size = UDim2.fromScale(1, 1);

					Blend.New "UICorner" {
						CornerRadius = UDim.new(0, 5);
					};

					Blend.New "UIStroke" {
						Color = Color3.fromRGB(40, 40, 40);
						Transparency = transparency;
					};

					Blend.New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal;
						HorizontalAlignment = Enum.HorizontalAlignment.Center;
						HorizontalFlex = Enum.UIFlexAlignment.Fill;
						Padding = UDim.new(0, 5);
						VerticalAlignment = Enum.VerticalAlignment.Center;
					};

					Blend.New "UIPadding" {
						PaddingBottom = UDim.new(0, 10);
						PaddingLeft = UDim.new(0, 10);
						PaddingRight = UDim.new(0, 10);
						PaddingTop = UDim.new(0, 10);
					};

					Blend.New "ImageLabel" {
						Name = "icon";
						BackgroundTransparency = 1;
						Image = "rbxassetid://6035078895";
						ImageColor3 = Color3.fromRGB(75, 75, 75);
						ImageTransparency = transparency;
						LayoutOrder = 1;
						Size = UDim2.fromScale(1, 1);

						Blend.New "UIAspectRatioConstraint" {
							AspectRatio = 1;
						};
					};

					Blend.New "TextBox" {
						Name = "input";
						BackgroundColor3 = Color3.fromRGB(163, 162, 165);
						BackgroundTransparency = 1;
						FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
						LayoutOrder = 2;
						PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
						Size = UDim2.fromScale(1, 1);
						TextColor3 = Color3.fromRGB(255, 255, 255);
						TextSize = 18;
						TextTransparency = transparency;
						TextXAlignment = Enum.TextXAlignment.Left;
						ZIndex = 5;

						PlaceholderText = Blend.Computed(targetColor, function(color)
							return color:ToHex()
						end);

						[Blend.Instance] = function(textBox)
							self._hexInput = textBox
							table.insert(self._tabInputMap, 2, textBox)
						end;

						[Blend.OnChange "Text"] = function(newText)
							if not self._hexInput then
								return
							end

							if newText == self._hexInput.PlaceholderText then
								return
							end

							if SearchUtils.stringIsHex(self._hexInput.Text) then
								local _, hex = SearchUtils.stringIsHex(self._hexInput.Text)
								self:SetColor(Color3.fromHex(hex))
							end
						end;

						[Blend.OnEvent "Focused"] = function()
							self:_handleFocused(self._hexInput)
						end;

						[Blend.OnEvent "FocusLost"] = function(enterPressed)
							if not self._hexInput then
								return
							end

							if enterPressed then
								if self._hexInput.Text ~= self._hexInput.PlaceholderText then
									if SearchUtils.stringIsHex(self._hexInput.Text) then
										local _, hex = SearchUtils.stringIsHex(self._hexInput.Text)
										self:SetColor(Color3.fromHex(hex))
									end

									self._hexInput.Text = ""
								else
									self._hexInput.Text = ""
								end
							else
								self._hexInput.Text = ""
							end

							self:_handleFocusLost()
						end;
					};
				};

				Blend.New "Frame" {
					Name = "rgbValues";
					LayoutOrder = 3;
					Size = UDim2.fromScale(1, 1);
					BackgroundTransparency = 1;

					Blend.New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal;
						HorizontalAlignment = Enum.HorizontalAlignment.Center;
						HorizontalFlex = Enum.UIFlexAlignment.Fill;
						Padding = UDim.new(0, 5);
						VerticalAlignment = Enum.VerticalAlignment.Center;
					};

					Blend.New "Frame" {
						Name = "r";
						BackgroundColor3 = Color3.fromRGB(15, 15, 15);
						BackgroundTransparency = transparency;
						LayoutOrder = 1;
						Size = UDim2.fromScale(1, 1);

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
						};

						Blend.New "UIStroke" {
							Color = Color3.fromRGB(40, 40, 40);
							Transparency = transparency;
						};

						Blend.New "UIPadding" {
							PaddingBottom = UDim.new(0, 10);
							PaddingLeft = UDim.new(0, 10);
							PaddingRight = UDim.new(0, 10);
							PaddingTop = UDim.new(0, 10);
						};

						Blend.New "TextBox" {
							Name = "input";
							BackgroundColor3 = Color3.fromRGB(163, 162, 165);
							BackgroundTransparency = 1;
							FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
							LayoutOrder = 2;
							PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
							Size = UDim2.fromScale(1, 1);
							TextColor3 = Color3.fromRGB(255, 255, 255);
							TextSize = 18;
							TextTransparency = transparency;
							ZIndex = 5;

							PlaceholderText = Blend.Computed(targetColor, function(color)
								return `{math.round(color.R * 255)}`
							end);

							[Blend.Instance] = function(textBox)
								self._rInput = textBox
								table.insert(self._tabInputMap, 3, textBox)
							end;

							[Blend.OnChange "Text"] = function(newText)
								if not self._rInput or not self._rInput:IsFocused() then
									return
								end

								if newText == self._rInput.PlaceholderText then
									return
								end

								if tonumber(newText) then
									local currentColor = self.CurrentColor.Value
									local r, g, b = math.clamp(tonumber(newText), 0, 255),
										math.clamp(math.round(currentColor.G * 255), 0, 255),
										math.clamp(math.round(currentColor.B * 255), 0, 255)

									self:SetColor(Color3.fromRGB(r, g, b))
								end
							end;

							[Blend.OnEvent "Focused"] = function()
								self:_handleFocused(self._rInput)
							end;

							[Blend.OnEvent "FocusLost"] = function(enterPressed)
								if not self._rInput then
									return
								end

								local text = self._rInput.Text
								if enterPressed then
									if text ~= self._rInput.PlaceholderText then
										if tonumber(text) then
											local currentColor = self.CurrentColor.Value
											local r, g, b = math.clamp(tonumber(text), 0, 255),
												math.clamp(math.round(currentColor.G * 255), 0, 255),
												math.clamp(math.round(currentColor.B * 255), 0, 255)

											self:SetColor(Color3.fromRGB(r, g, b))
										end

										self._rInput.Text = ""
									else
										self._rInput.Text = ""
									end
								else
									self._rInput.Text = ""
								end

								self:_handleFocusLost()
							end;
						};
					};

					Blend.New "Frame" {
						Name = "g";
						BackgroundColor3 = Color3.fromRGB(15, 15, 15);
						BackgroundTransparency = transparency;
						LayoutOrder = 2;
						Size = UDim2.fromScale(1, 1);

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
						};

						Blend.New "UIStroke" {
							Color = Color3.fromRGB(40, 40, 40);
							Transparency = transparency;
						};

						Blend.New "UIPadding" {
							PaddingBottom = UDim.new(0, 10);
							PaddingLeft = UDim.new(0, 10);
							PaddingRight = UDim.new(0, 10);
							PaddingTop = UDim.new(0, 10);
						};

						Blend.New "TextBox" {
							Name = "input";
							BackgroundColor3 = Color3.fromRGB(163, 162, 165);
							BackgroundTransparency = 1;
							FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
							LayoutOrder = 2;
							PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
							Size = UDim2.fromScale(1, 1);
							TextColor3 = Color3.fromRGB(255, 255, 255);
							TextSize = 18;
							TextTransparency = transparency;
							ZIndex = 5;

							PlaceholderText = Blend.Computed(targetColor, function(color)
								return `{math.round(color.G * 255)}`
							end);

							[Blend.Instance] = function(textBox)
								self._gInput = textBox
								table.insert(self._tabInputMap, 4, textBox)
							end;

							[Blend.OnChange "Text"] = function(newText)
								if not self._gInput or not self._gInput:IsFocused() then
									return
								end

								if newText == self._gInput.PlaceholderText then
									return
								end

								if tonumber(newText) then
									local currentColor = self.CurrentColor.Value
									local r, g, b = math.clamp(math.round(currentColor.R * 255), 0, 255),
										math.clamp(tonumber(newText), 0, 255),
										math.clamp(math.round(currentColor.B * 255), 0, 255)

									self:SetColor(Color3.fromRGB(r, g, b))
								end
							end;

							[Blend.OnEvent "Focused"] = function()
								self:_handleFocused(self._gInput)
							end;

							[Blend.OnEvent "FocusLost"] = function(enterPressed)
								if not self._gInput then
									return
								end

								local text = self._gInput.Text
								if enterPressed then
									if text ~= self._gInput.PlaceholderText then
										if tonumber(text) then
											local currentColor = self.CurrentColor.Value
											local r, g, b = math.clamp(math.round(currentColor.R * 255), 0, 255),
												math.clamp(tonumber(text), 0, 255),
												math.clamp(math.round(currentColor.B * 255), 0, 255)

											self:SetColor(Color3.fromRGB(r, g, b))
										end

										self._gInput.Text = ""
									else
										self._gInput.Text = ""
									end
								else
									self._gInput.Text = ""
								end

								self:_handleFocusLost()
							end;
						};
					};

					Blend.New "Frame" {
						Name = "b";
						BackgroundColor3 = Color3.fromRGB(15, 15, 15);
						BackgroundTransparency = transparency;
						LayoutOrder = 3;
						Size = UDim2.fromScale(1, 1);

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
						};

						Blend.New "UIStroke" {
							Color = Color3.fromRGB(40, 40, 40);
							Transparency = transparency;
						};

						Blend.New "UIPadding" {
							PaddingBottom = UDim.new(0, 10);
							PaddingLeft = UDim.new(0, 10);
							PaddingRight = UDim.new(0, 10);
							PaddingTop = UDim.new(0, 10);
						};

						Blend.New "TextBox" {
							Name = "input";
							BackgroundColor3 = Color3.fromRGB(163, 162, 165);
							BackgroundTransparency = 1;
							FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
							LayoutOrder = 2;
							PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
							Size = UDim2.fromScale(1, 1);
							TextColor3 = Color3.fromRGB(255, 255, 255);
							TextSize = 18;
							TextTransparency = transparency;
							ZIndex = 5;

							PlaceholderText = Blend.Computed(targetColor, function(color)
								return `{math.round(color.B * 255)}`
							end);

							[Blend.Instance] = function(textBox)
								self._bInput = textBox
								table.insert(self._tabInputMap, 5, textBox)
							end;

							[Blend.OnChange "Text"] = function(newText)
								if not self._bInput or not self._bInput:IsFocused() then
									return
								end

								if newText == self._bInput.PlaceholderText then
									return
								end

								if tonumber(newText) then
									local currentColor = self.CurrentColor.Value
									local r, g, b = math.clamp(math.round(currentColor.R * 255), 0, 255),
										math.clamp(math.round(currentColor.G * 255), 0, 255),
										math.clamp(tonumber(newText), 0, 255)

									self:SetColor(Color3.fromRGB(r, g, b))
								end
							end;

							[Blend.OnEvent "Focused"] = function()
								self:_handleFocused(self._bInput)
							end;

							[Blend.OnEvent "FocusLost"] = function(enterPressed)
								if not self._bInput then
									return
								end

								local text = self._bInput.Text
								if enterPressed then
									if text ~= self._bInput.PlaceholderText then
										if tonumber(text) then
											local currentColor = self.CurrentColor.Value
											local r, g, b = math.clamp(math.round(currentColor.R * 255), 0, 255),
												math.clamp(math.round(currentColor.G * 255), 0, 255),
												math.clamp(tonumber(text), 0, 255)

											self:SetColor(Color3.fromRGB(r, g, b))
										end

										self._bInput.Text = ""
									else
										self._bInput.Text = ""
									end
								else
									self._bInput.Text = ""
								end

								self:_handleFocusLost()
							end;
						};
					};
				};
			};
		};

		Blend.New "Frame" {
			Name = "divider";
			AnchorPoint = Vector2.new(0, 1);
			BackgroundColor3 = Color3.fromRGB(35, 35, 35);
			BackgroundTransparency = transparency;
			Position = UDim2.new(0, 0, 1, -4);
			Size = UDim2.new(1, 0, 0, 1);
			ZIndex = 0;
		};
	};
end

function ColorPickerPane:_handleFocusLost()
	if not UserInputService:GetFocusedTextBox() then
		self._tabInputIndex.Value = nil
	end
end

function ColorPickerPane:_handleFocused(input)
	if not input then
		return
	end

	if not self._tabInputIndex.Value then
		local index = table.find(self._tabInputMap, input)
		self._tabInputIndex.Value = index
	end

	local placeholder = input.PlaceholderText

	input.Text = placeholder
	input.SelectionStart = 0
	input.CursorPosition = #placeholder + 1
end

function ColorPickerPane:_isValidInput(inputObject)
	return inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch
end

function ColorPickerPane:_shiftPressed()
	local shiftPressed = false
	for _, inputObject in UserInputService:GetKeysPressed() do
		if inputObject.KeyCode == Enum.KeyCode.LeftShift then
			shiftPressed = true
			break
		end
	end
	return shiftPressed
end

return ColorPickerPane