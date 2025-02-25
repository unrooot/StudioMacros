local require = require(script.Parent.loader).load(script)

local TweenService = game:GetService("TweenService")

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local Rx = require("Rx")
local ValueObject = require("ValueObject")

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local ColorPickerPane = setmetatable({}, BasicPane)
ColorPickerPane.ClassName = "ColorPickerPane"
ColorPickerPane.CustomResultType = "Color"
ColorPickerPane.__index = ColorPickerPane

function ColorPickerPane.new()
	local self = setmetatable(BasicPane.new(), ColorPickerPane)

	self._currentColor = self._maid:Add(ValueObject.new(Color3.new(1, 1, 1)))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._yPosition = self._maid:Add(ValueObject.new(0))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function ColorPickerPane:SetColor(color)
	return self._currentColor:Mount(color)
end

function ColorPickerPane:GetYPosition()
	return self._yPosition.Value
end

function ColorPickerPane:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 30, 0.7)
	local transparency = props.Transparency

	local hue = self._maid:Add(Blend.State(0))
	local saturation = self._maid:Add(Blend.State(0))
	local brightness = self._maid:Add(Blend.State(0))

	self._maid:GiveTask(self._currentColor:Observe():Subscribe(function(color)
		local h, s, v = color:ToHSV()

		hue.Value = h
		saturation.Value = s
		brightness.Value = v
	end))

	local percentHue = Blend.Spring(hue, 35, 0.9)
	local percentSaturation = Blend.Spring(saturation, 35, 0.9)
	local percentBrightness = Blend.Spring(brightness, 35, 0.9)

	local pickerCursorX = Blend.Spring(percentSaturation:Pipe({
		Rx.map(function(percent)
			return math.abs(percent - 1)
		end);
	}), 35, 0.7)

	local pickerCursorY = Blend.Spring(percentBrightness:Pipe({
		Rx.map(function(percent)
			return math.abs(percent - 1)
		end);
	}), 35, 0.7)

	local oldColor = self._maid:Add(Blend.State(self._currentColor.Value))
	local targetColor = self._maid:Add(Instance.new("Color3Value"))

	self._maid:GiveTask(self._currentColor:Observe():Subscribe(function(newColor)
		TweenService:Create(targetColor, TWEEN_INFO, {
			Value = newColor
		}):Play()

		oldColor.Value = newColor
	end))

	return Blend.New "Frame" {
		Name = "ColorPickerPane";
		BackgroundTransparency = 1;
		LayoutOrder = -1;
		LayoutOrder = -9e9;
		Size = UDim2.new(1, 0, 0, 160);
		Parent = props.TargetParent;

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
				Padding = UDim.new(0, 10);
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
			};

			Blend.New "Frame" {
				Name = "selection";
				BackgroundTransparency = 1;
				LayoutOrder = 2;
				Size = UDim2.fromScale(0.5, 1);

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
						Position = UDim2.fromScale(0.5, 0.5);
						AnchorPoint = Vector2.new(0.5, 0.5);
						Size = UDim2.fromScale(1, 1);
						BackgroundTransparency = 1;

						Blend.New "Frame" {
							Position = UDim2.fromScale(0.5, 0.5);
							AnchorPoint = Vector2.new(0.5, 0.5);
							Size = UDim2.fromScale(1, 1);
							BackgroundTransparency = 1;

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
								Position = UDim2.fromScale(0.5, 0.5);
								AnchorPoint = Vector2.new(0.5, 0.5);
								Size = UDim2.fromScale(1, 1);
								BorderColor3 = Color3.fromRGB(27, 42, 53);

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
				LayoutOrder = 3;
				Position = UDim2.fromScale(0.5, 0);
				Size = UDim2.new(0, 40, 1, 0);
				BackgroundTransparency = 1;

				Blend.New "UIFlexItem" { };

				Blend.New "Frame" {
					Name = "hue";
					Position = UDim2.fromScale(0, 1);
					AnchorPoint = Vector2.new(0, 1);
					Size = UDim2.new(0, 15, 1, 0);
					BackgroundTransparency = 1;

					Blend.New "Frame" {
						Name = "container";
						Size = UDim2.fromScale(1, 1);
						BorderColor3 = Color3.fromRGB(27, 42, 53);
						ZIndex = 2;

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
							Size = UDim2.fromScale(1.5, 1);

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
					};
				};

				Blend.New "Frame" {
					Name = "brightness";
					Position = UDim2.fromScale(1, 1);
					AnchorPoint = Vector2.new(1, 1);
					Size = UDim2.new(0, 15, 1, 0);
					BackgroundTransparency = 1;

					Blend.New "Frame" {
						Name = "container";
						Size = UDim2.fromScale(1, 1);
						BorderColor3 = Color3.fromRGB(27, 42, 53);
						ZIndex = 2;

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
							AnchorPoint = Vector2.new(0.5, 1);
							BackgroundTransparency = transparency;
							Size = UDim2.fromScale(1.5, 1);

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
					};
				};
			};

			Blend.New "Frame" {
				Name = "inputs";
				LayoutOrder = 4;
				Position = UDim2.fromScale(0.780371, 0);
				Size = UDim2.fromScale(0.2, 1);
				BackgroundTransparency = 1;

				Blend.New "UIListLayout" {
					HorizontalAlignment = Enum.HorizontalAlignment.Center;
					Padding = UDim.new(0, 5);
					VerticalAlignment = Enum.VerticalAlignment.Center;
					VerticalFlex = Enum.UIFlexAlignment.Fill;
				};

				Blend.New "Frame" {
					Name = "rgb";
					LayoutOrder = 1;
					Size = UDim2.fromScale(1, 1);
					BackgroundColor3 = Color3.fromRGB(15, 15, 15);
					BorderColor3 = Color3.fromRGB(27, 42, 53);

					Blend.New "UICorner" {
						CornerRadius = UDim.new(0, 5);
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
						LayoutOrder = 1;
						Size = UDim2.fromScale(1, 1);
						BackgroundColor3 = Color3.fromRGB(15, 15, 15);
						BorderColor3 = Color3.fromRGB(27, 42, 53);

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
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
						};
					};

					Blend.New "Frame" {
						Name = "g";
						LayoutOrder = 2;
						Size = UDim2.fromScale(1, 1);
						BackgroundColor3 = Color3.fromRGB(15, 15, 15);
						BorderColor3 = Color3.fromRGB(27, 42, 53);
						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
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
						};
					};

					Blend.New "Frame" {
						Name = "b";
						LayoutOrder = 3;
						Size = UDim2.fromScale(1, 1);
						BackgroundColor3 = Color3.fromRGB(15, 15, 15);
						BorderColor3 = Color3.fromRGB(27, 42, 53);

						Blend.New "UICorner" {
							CornerRadius = UDim.new(0, 5);
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
						};
					};
				};
			};
		};
	};
end

return ColorPickerPane