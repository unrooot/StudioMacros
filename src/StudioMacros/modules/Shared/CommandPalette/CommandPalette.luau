local require = require(script.Parent.loader).load(script)

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local CommandGroup = require("CommandGroup")
local Fzy = require("Fzy")
local ObservableList = require("ObservableList")
local ObservableSortedList = require("ObservableSortedList")
local Rx = require("Rx")
local RxBrioUtils = require("RxBrioUtils")
local ValueObject = require("ValueObject")

local FZY_CONFIG = Fzy.createConfig()
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local CommandPalette = setmetatable({}, BasicPane)
CommandPalette.ClassName = "CommandPalette"
CommandPalette.__index = CommandPalette

function CommandPalette.new()
	local self = setmetatable(BasicPane.new(), CommandPalette)

	self._entries = self._maid:Add(ObservableList.new())
	self._entryHeight = self._maid:Add(ValueObject.new(45))
	self._inputFocused = self._maid:Add(ValueObject.new(false))
	self._inputModel = self._maid:Add(ButtonHighlightModel.new())
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))
	self._searchEntries = self._maid:Add(ObservableSortedList.new(true))
	self._searchQuery = self._maid:Add(ValueObject.new(""))
	self._selectedEntry = self._maid:Add(ValueObject.new(nil))
	self._selectedEntryIndex = self._maid:Add(ValueObject.new(0))
	self._selectedGroupEntryIndex = self._maid:Add(ValueObject.new(0))
	self._targetEntryParent = self._maid:Add(ValueObject.new(nil))

	self:_handleInput()

	self._maid:GiveTask(Rx.combineLatest({
		CurrentEntry = self._selectedEntryIndex:Observe();
		CurrentGroup = self._selectedGroupEntryIndex:Observe();
		SearchQuery = self._searchQuery:Observe();
	}):Subscribe(function(data)
		if data.SearchQuery ~= "" then
			self._selectedEntry.Value = self._searchEntries:GetList()[data.CurrentEntry]
		else
			if data.CurrentGroup == 0 then
				return
			end

			local groupEntries = self._entries:GetList()
			local currentGroup = groupEntries[data.CurrentGroup]
			local currentEntries = currentGroup:GetEntries()

			if data.CurrentEntry == 0 then
				self._selectedEntry.Value = currentEntries[1]
			else
				self._selectedEntry.Value = currentEntries[data.CurrentEntry + 1]
			end
		end
	end))

	self._maid:GiveTask(self._selectedEntry:Observe():Subscribe(function(entry)
		if self._previousEntry then
			self._previousEntry:SetIsSelected(false)
			self._previousEntry = nil
		end

		if not entry then
			return
		end

		entry:SetIsSelected(true)
		self._previousEntry = entry
	end))

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		if self._input then
			if isVisible then
				self._input:CaptureFocus()

				if #self._entries:GetList() > 0 then
					if self._searchQuery.Value ~= "" then
						self._selectedGroupEntryIndex.Value = 0
						self._selectedEntryIndex.Value = 1
					else
						self._selectedGroupEntryIndex.Value = 1
						self._selectedEntryIndex.Value = 0
					end
				end
			else
				self._input.Text = ""
			end
		end

		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function CommandPalette:AddGroup(groupData)
	if not groupData then
		return
	end

	local groupEntry = self._maid:Add(CommandGroup.new())
	groupEntry:SetHeader(groupData.Name, groupData.Icon)

	self._maid:GiveTask(self._entries:Add(groupEntry))
	self._maid:GiveTask(groupEntry._entries:ObserveItemsBrio():Subscribe(function(entryBrio)
		if entryBrio:IsDead() then
			return
		end

		local maid, entry = entryBrio:ToMaidAndValue()
		if not entry then
			return
		end

		entry:SetGroupIcon(groupData.Icon)
		entry:SetGroupName(groupData.Name)

		maid:GiveTask(entry.SearchScore:ObserveBrio():Subscribe(function(scoreBrio)
			if scoreBrio:IsDead() then
				return
			end

			local score = scoreBrio:GetValue()
			if score == nil or score == -math.huge then
				return
			end

			scoreBrio:ToMaid():GiveTask(self._searchEntries:Add(entry, entry.SearchScore:Observe()))
		end))
	end))

	return groupEntry
end

function CommandPalette:_handleInput()
	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input, gpe)
		local keysPressed = UserInputService:GetKeysPressed()
		local upPressed, downPressed, ctrlPressed = false, false, false

		if input.KeyCode == Enum.KeyCode.Up then
			upPressed = true
		elseif input.KeyCode == Enum.KeyCode.Down then
			downPressed = true
		end

		-- Ctrl+J/Ctrl+K support
		for _, inputObject in keysPressed do
			if inputObject.KeyCode == Enum.KeyCode.LeftControl or inputObject.KeyCode == Enum.KeyCode.RightControl then
				ctrlPressed = true
				break
			end
		end

		if ctrlPressed then
			for _, inputObject in keysPressed do
				if inputObject.KeyCode == Enum.KeyCode.J then
					downPressed = true
				elseif inputObject.KeyCode == Enum.KeyCode.K then
					upPressed = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			if self._input.Text == "" then
				self:Hide()
			else
				self._input.Text = ""
				self._input:CaptureFocus()
			end
		elseif upPressed or downPressed then
			if self._searchQuery.Value ~= "" then
				self._selectedGroupEntryIndex.Value = 0

				local selectedEntryIndex = self._selectedEntryIndex.Value
				if upPressed and selectedEntryIndex - 1 > 0 then
					self._selectedEntryIndex.Value -= 1
				elseif downPressed and selectedEntryIndex + 1 <= #self._searchEntries:GetList() then
					self._selectedEntryIndex.Value += 1
				end

				return
			end

			local selectedEntry = self._selectedEntryIndex.Value
			local selectedGroup = self._selectedGroupEntryIndex.Value
			local groupEntries = self._entries:GetList()

			if selectedGroup == 0 and selectedEntry == 0 then
				if upPressed then
					-- self._selectedGroupEntryIndex.Value = #groupEntries
				else
					self._selectedGroupEntryIndex.Value += 1
				end
				return
			end

			local currentGroup = groupEntries[selectedGroup]
			if not currentGroup then
				return
			end

			local currentGroupEntries = #currentGroup:GetEntries() - 1

			if upPressed then
				if selectedEntry - 1 >= 0 and not currentGroup:IsCollapsed() then
					self._selectedEntryIndex.Value -= 1
				elseif selectedEntry == 0 then
					if selectedGroup - 1 <= 0 then
						-- self._selectedGroupEntryIndex.Value = #groupEntries
						return
					else
						self._selectedGroupEntryIndex.Value -= 1
					end

					local newGroup = groupEntries[self._selectedGroupEntryIndex.Value]
					if newGroup:IsCollapsed() then
						self._selectedEntryIndex.Value = 0
					else
						self._selectedEntryIndex.Value = #newGroup:GetEntries() - 1
					end
				end
			else
				if selectedEntry + 1 <= currentGroupEntries and not currentGroup:IsCollapsed() then
					self._selectedEntryIndex.Value += 1
				elseif ((selectedEntry + 1 > currentGroupEntries) or currentGroup:IsCollapsed()) and selectedGroup + 1 <= #groupEntries then
					self._selectedEntryIndex.Value = 0
					self._selectedGroupEntryIndex.Value += 1
				end
			end
		end
	end))
end

function CommandPalette:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 50, 0.9)
	local percentAlpha = Blend.AccelTween(target, target:Pipe({
		Rx.map(function(value)
			return value == 1 and 400 or 2000
		end)
	}))

	self._maid:GiveTask(Blend.Computed(percentAlpha, function(percent)
		local entries = self._entries:GetList()
		local entryCount = math.max(1, #entries)

		for index, entry in entries do
			local progress = (index - 1) / entryCount + 1e-1
			entry:SetVisible(progress <= percent)
		end
	end):Subscribe())

	local transparency = Blend.Computed(percentAlpha, function(percent)
		return 1 - percent
	end)

	local contentHeight = self._maid:Add(Blend.State(0))
	local windowHeight = self._maid:Add(Blend.State(0))

	local scrollThicknessTarget = Blend.Computed(contentHeight, windowHeight, function(content, window)
		if not self:IsVisible() then
			return
		end

		return content > window and 1 or 0
	end)

	local percentScrollThickness = Blend.AccelTween(scrollThicknessTarget, 500)

	local containerPercent = Blend.Spring(Blend.Computed(contentHeight, windowHeight, function(content, window)
		return math.min(content + 92, window)
	end), 30, 1);

	self._maid:GiveTask(Blend.Computed(self._selectedEntry, function(entry)
		if not self._entriesFrame then
			return
		end

		if entry then
			local canvasPosition = self._entriesFrame.CanvasPosition.Y
			local framePosition = self._entriesFrame.AbsolutePosition.Y
			local frameSize = self._entriesFrame.AbsoluteSize.Y

			local entryPosition = entry:GetYPosition() - framePosition
			local entrySize = self._entryHeight.Value
			local entryBottom = entryPosition + entrySize

			if entryPosition < canvasPosition then
				TweenService:Create(self._entriesFrame, TWEEN_INFO, {
					CanvasPosition = Vector2.new(0, entryPosition)
				}):Play()
			elseif entryBottom > frameSize then
				TweenService:Create(self._entriesFrame, TWEEN_INFO, {
					CanvasPosition = Vector2.new(0, canvasPosition + (entryBottom - frameSize) + 1)
				}):Play()
			end
		end
	end):Subscribe())

	return Blend.New "Frame" {
		Name = "CommandPalette";
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundTransparency = 1;
		Position = UDim2.fromScale(0.5, 0.5);
		Size = UDim2.fromScale(0.4, 0.75);

		[Blend.OnChange "AbsoluteSize"] = function(windowSize)
			windowHeight.Value = math.round(windowSize.Y) - 90
		end;

		Blend.New "UISizeConstraint" {
			MinSize = Vector2.new(500, 0);
		};

		Blend.New "Frame" {
			Name = "wrapper";
			AnchorPoint = Vector2.new(0.5, 0);
			BackgroundTransparency = 1;
			Position = UDim2.fromScale(0.5, 0);

			Size = Blend.Computed(containerPercent, contentHeight, windowHeight, function(percent, content, window)
				if content > window then
					return UDim2.fromScale(1, 1)
				end

				return UDim2.new(1, 0, 0, math.min(percent, window));
			end);

			Blend.New "UIScale" {
				Scale = Blend.Computed(percentVisible, function(percent)
					if percent >= 0.98 then
						percent = 1
					end

					return 0.9 + (percent * 0.1)
				end);
			};

			Blend.New "ImageLabel" {
				Name = "shadow";
				AnchorPoint = Vector2.new(0.5, 0.5);
				BackgroundColor3 = Color3.fromRGB(163, 162, 165);
				BackgroundTransparency = 1;
				Image = "rbxassetid://6150493168";
				ImageColor3 = Color3.fromRGB(0, 0, 0);
				Position = UDim2.fromScale(0.5, 0.5);
				ScaleType = Enum.ScaleType.Slice;
				Size = UDim2.new(1, 50, 1, 50);
				SliceCenter = Rect.new(Vector2.new(100, 100), Vector2.new(100, 100));
				SliceScale = 0.4;
				ZIndex = -10;

				ImageTransparency = Blend.Computed(transparency, function(percent)
					return 0.9 + (percent * 0.1)
				end);
			};

			Blend.New "Frame" {
				Name = "container";
				BackgroundColor3 = Color3.fromRGB(30, 30, 30);
				BackgroundTransparency = transparency;
				Size = UDim2.fromScale(1, 1);

				Blend.New "UICorner" {
					CornerRadius = UDim.new(0, 10);
				};

				Blend.New "UIStroke" {
					Color = Color3.fromRGB(40, 40, 40);
					Transparency = transparency;
				};

				Blend.New "Frame" {
					Name = "search";
					BackgroundColor3 = Color3.fromRGB(15, 15, 15);
					BackgroundTransparency = transparency;
					Size = UDim2.new(1, 0, 0, 40);

					Blend.New "UICorner" {
						CornerRadius = UDim.new(0, 10);
					};

					Blend.New "Frame" {
						Name = "cover";
						AnchorPoint = Vector2.new(0, 1);
						BackgroundColor3 = Color3.fromRGB(15, 15, 15);
						BackgroundTransparency = transparency;
						Position = UDim2.fromScale(0, 1);
						Size = UDim2.new(1, 0, 0, 10);
						ZIndex = -5;
					};

					Blend.New "Frame" {
						Name = "container";
						BackgroundTransparency = 1;
						Size = UDim2.fromScale(1, 1);

						Blend.New "UIPadding" {
							PaddingBottom = UDim.new(0, 10);
							PaddingLeft = UDim.new(0, 10);
							PaddingRight = UDim.new(0, 10);
							PaddingTop = UDim.new(0, 10);
						};

						Blend.New "UIListLayout" {
							FillDirection = Enum.FillDirection.Horizontal;
							HorizontalAlignment = Enum.HorizontalAlignment.Center;
							HorizontalFlex = Enum.UIFlexAlignment.Fill;
							Padding = UDim.new(0, 5);
							VerticalAlignment = Enum.VerticalAlignment.Center;
						};

						Blend.New "ImageLabel" {
							Name = "searchIcon";
							BackgroundTransparency = 1;
							Image = "rbxassetid://6031154871";
							ImageColor3 = Color3.fromRGB(150, 150, 150);
							ImageTransparency = transparency;
							Size = UDim2.fromScale(1, 1);

							Blend.New "UIAspectRatioConstraint" {
								AspectRatio = 1;
							};
						};

						Blend.New "TextBox" {
							Name = "input";
							BackgroundTransparency = 1;
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
							PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
							PlaceholderText = "select a command...";
							Position = UDim2.fromScale(0.04, 0);
							Size = UDim2.fromScale(0.9, 1);
							TextColor3 = Color3.fromRGB(220, 220, 220);
							TextSize = 15;
							TextTransparency = transparency;
							TextXAlignment = Enum.TextXAlignment.Left;

							Blend.New "UITextSizeConstraint" {
								MaxTextSize = 16;
							};

							[Blend.Instance] = function(input)
								self._input = input
							end;

							[Blend.OnChange "Text"] = function(text)
								self._searchQuery.Value = string.gsub(text, "%s+", " ")

								if #self._entries:GetList() > 0 then
									if self._searchQuery.Value ~= "" then
										self._targetEntryParent.Value = self._entriesFrame
										self._selectedGroupEntryIndex.Value = 0
										self._selectedEntryIndex.Value = 1
									else
										self._targetEntryParent.Value = nil
										self._selectedGroupEntryIndex.Value = 1
										self._selectedEntryIndex.Value = 0
									end
								end
							end;

							[Blend.OnEvent "Focused"] = function()
								self._inputFocused.Value = true
							end;

							[Blend.OnEvent "FocusLost"] = function(enterPressed)
								local selectedEntry = self._selectedEntry.Value
								local refocusInput = false
								local shiftPressed = false

								if enterPressed and selectedEntry then
									if selectedEntry:IsGroupHeader() then
										local selectedGroup = self._selectedGroupEntryIndex.Value
										local groupEntry = self._entries:GetList()[selectedGroup]

										if not groupEntry then
											return
										end

										groupEntry:SetIsCollapsed(not groupEntry:IsCollapsed())
										refocusInput = true
									else
										-- Hold shift to trigger without closing the palette
										for _, inputObject in UserInputService:GetKeysPressed() do
											if inputObject.KeyCode == Enum.KeyCode.LeftShift then
												shiftPressed = true
												break
											end
										end

										selectedEntry.Activated:Fire(shiftPressed)
										if shiftPressed then
											refocusInput = true
										end
									end
								end

								if refocusInput then
									task.spawn(function()
										RunService.RenderStepped:Wait()
										self._input:CaptureFocus()
									end)
								else
									self._inputFocused.Value = false
								end
							end;
						};

						Blend.New "ImageLabel" {
							Name = "detailsIcon";
							AnchorPoint = Vector2.new(1, 0);
							BackgroundTransparency = 1;
							Image = "rbxassetid://6022668888";
							ImageColor3 = Color3.fromRGB(75, 75, 75);
							ImageTransparency = transparency;
							Position = UDim2.fromScale(1, 0);
							Size = UDim2.fromScale(1, 1);

							Blend.New "UIAspectRatioConstraint" {
								AspectRatio = 1;
							};
						};
					};

					Blend.New "TextButton" {
						Name = "button";
						BackgroundTransparency = 1;
						Size = UDim2.fromScale(1, 1);
						ZIndex = 5;

						Visible = Blend.Computed(self:ObserveVisible(), self._inputFocused, function(isVisible, isFocused)
							if not isVisible then
								return false
							else
								return not isFocused
							end
						end);

						[Blend.Instance] = function(button)
							self._inputModel:SetButton(button)
						end;

						[Blend.OnEvent "Activated"] = function()
							self._input:CaptureFocus()
						end;
					};
				};

				Blend.New "Frame" {
					Name = "body";
					BackgroundTransparency = 1;
					Position = UDim2.fromOffset(0, 40);
					Size = UDim2.new(1, 0, 1, -80);

					Blend.New "UIPadding" {
						PaddingBottom = UDim.new(0, 5);
						PaddingLeft = UDim.new(0, 5);
						PaddingRight = UDim.new(0, 5);
						PaddingTop = UDim.new(0, 5);
					};

					Blend.New "ScrollingFrame" {
						Name = "entries";
						Active = true;
						BackgroundTransparency = 1;
						ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50);
						ScrollBarImageTransparency = transparency;
						ScrollingDirection = Enum.ScrollingDirection.Y;
						ScrollingEnabled = self:ObserveVisible();
						Size = UDim2.fromScale(1, 1);
						VerticalScrollBarInset = Enum.ScrollBarInset.Always;

						CanvasSize = Blend.Computed(contentHeight, function(contentHeight)
							return UDim2.fromOffset(0, contentHeight + 2);
						end);

						ScrollBarThickness = Blend.Computed(percentScrollThickness, function(percent)
							return 10 * percent
						end);

						Visible = Blend.Computed(percentVisible, function(percent)
							return percent > 0.01
						end);

						[Blend.Instance] = function(scrollingFrame)
							self._entriesFrame = scrollingFrame
						end;

						Blend.New "UIPadding" {
							PaddingBottom = UDim.new(0, 4);
							PaddingLeft = UDim.new(0, 1);
							PaddingTop = UDim.new(0, 1);

							PaddingRight = Blend.Computed(contentHeight, windowHeight, function(content, window)
								return UDim.new(0, content > window and 5 or 1)
							end);
						};

						Blend.New "UIListLayout" {
							HorizontalAlignment = Enum.HorizontalAlignment.Center;

							[Blend.OnChange "AbsoluteContentSize"] = function(size)
								if not self:IsVisible() then
									return
								end

								contentHeight.Value = math.round(size.Y)
							end;
						};

						self._entries:ObserveItemsBrio():Pipe({
							RxBrioUtils.map(function(groupEntry)
								return groupEntry:Render({
									EntryHeight = self._entryHeight;
									FzyConfig = FZY_CONFIG;
									SearchQuery = self._searchQuery;
									TargetParent = self._targetEntryParent;
								})
							end);
						});
					};
				};

				Blend.New "Frame" {
					Name = "footer";
					AnchorPoint = Vector2.new(0, 1);
					BackgroundTransparency = 1;
					Position = UDim2.fromScale(0, 1);
					Size = UDim2.new(1, 0, 0, 40);

					Blend.New "Frame" {
						Name = "container";
						BackgroundTransparency = 1;
						Size = UDim2.fromScale(1, 1);

						Blend.New "UIPadding" {
							PaddingBottom = UDim.new(0, 10);
							PaddingLeft = UDim.new(0, 5);
							PaddingRight = UDim.new(0, 5);
							PaddingTop = UDim.new(0, 10);
						};

						Blend.New "UIListLayout" {
							FillDirection = Enum.FillDirection.Horizontal;
							HorizontalAlignment = Enum.HorizontalAlignment.Center;
							Padding = UDim.new(0, 5);
							VerticalAlignment = Enum.VerticalAlignment.Center;
						};

						Blend.New "Frame" {
							Name = "shortcut";
							AutomaticSize = Enum.AutomaticSize.X;
							BackgroundColor3 = Color3.fromRGB(25, 25, 25);
							BackgroundTransparency = transparency;
							LayoutOrder = 1;
							Size = UDim2.fromScale(0, 1);

							Blend.New "UIPadding" {
								PaddingBottom = UDim.new(0, 5);
								PaddingLeft = UDim.new(0, 5);
								PaddingRight = UDim.new(0, 5);
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
								AutomaticSize = Enum.AutomaticSize.X;
								BackgroundTransparency = 1;
								FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
								Size = UDim2.fromScale(0, 1);
								Text = "Up";
								TextColor3 = Color3.fromRGB(90, 90, 90);
								TextTransparency = transparency;
							};
						};

						Blend.New "Frame" {
							Name = "shortcut";
							AutomaticSize = Enum.AutomaticSize.X;
							BackgroundColor3 = Color3.fromRGB(25, 25, 25);
							BackgroundTransparency = transparency;
							LayoutOrder = 2;
							Size = UDim2.fromScale(0, 1);

							Blend.New "UIPadding" {
								PaddingBottom = UDim.new(0, 5);
								PaddingLeft = UDim.new(0, 5);
								PaddingRight = UDim.new(0, 5);
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
								AutomaticSize = Enum.AutomaticSize.X;
								BackgroundTransparency = 1;
								FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
								Size = UDim2.fromScale(0, 1);
								Text = "Down";
								TextColor3 = Color3.fromRGB(90, 90, 90);
								TextTransparency = transparency;
							};
						};

						Blend.New "TextLabel" {
							Name = "label";
							AutomaticSize = Enum.AutomaticSize.X;
							BackgroundTransparency = 1;
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
							LayoutOrder = 3;
							Size = UDim2.fromScale(0, 1);
							Text = "to navigate";
							TextColor3 = Color3.fromRGB(110, 110, 110);
							TextTransparency = transparency;
						};

						Blend.New "Frame" {
							Name = "buffer";
							BackgroundTransparency = 1;
							LayoutOrder = 4;
							Size = UDim2.new(0, 5, 1, 0);
						};

						Blend.New "Frame" {
							Name = "shortcut";
							AutomaticSize = Enum.AutomaticSize.X;
							BackgroundColor3 = Color3.fromRGB(25, 25, 25);
							BackgroundTransparency = transparency;
							LayoutOrder = 5;
							Size = UDim2.fromScale(0, 1);

							Blend.New "UIPadding" {
								PaddingBottom = UDim.new(0, 5);
								PaddingLeft = UDim.new(0, 5);
								PaddingRight = UDim.new(0, 5);
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
								AutomaticSize = Enum.AutomaticSize.X;
								BackgroundTransparency = 1;
								FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
								Size = UDim2.fromScale(0, 1);
								Text = "Enter";
								TextColor3 = Color3.fromRGB(90, 90, 90);
								TextTransparency = transparency;
							};
						};

						Blend.New "TextLabel" {
							Name = "label";
							AutomaticSize = Enum.AutomaticSize.X;
							BackgroundTransparency = 1;
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
							LayoutOrder = 6;
							Size = UDim2.fromScale(0, 1);
							Text = "to use";
							TextColor3 = Color3.fromRGB(110, 110, 110);
							TextTransparency = transparency;
						};

						Blend.New "Frame" {
							Name = "buffer";
							BackgroundTransparency = 1;
							LayoutOrder = 7;
							Size = UDim2.new(0, 5, 1, 0);
						};

						Blend.New "Frame" {
							Name = "shortcut";
							AutomaticSize = Enum.AutomaticSize.X;
							BackgroundColor3 = Color3.fromRGB(25, 25, 25);
							BackgroundTransparency = transparency;
							LayoutOrder = 8;
							Size = UDim2.fromScale(0, 1);

							Blend.New "UIPadding" {
								PaddingBottom = UDim.new(0, 5);
								PaddingLeft = UDim.new(0, 5);
								PaddingRight = UDim.new(0, 5);
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
								AutomaticSize = Enum.AutomaticSize.X;
								BackgroundTransparency = 1;
								FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
								Size = UDim2.fromScale(0, 1);
								Text = "Escape";
								TextColor3 = Color3.fromRGB(90, 90, 90);
								TextTransparency = transparency;
							};
						};

						Blend.New "TextLabel" {
							Name = "label";
							AutomaticSize = Enum.AutomaticSize.X;
							BackgroundTransparency = 1;
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
							LayoutOrder = 9;
							Size = UDim2.fromScale(0, 1);
							Text = "to dismiss";
							TextColor3 = Color3.fromRGB(110, 110, 110);
							TextTransparency = transparency;
						};
					};

					Blend.New "Frame" {
						Name = "divider";
						BackgroundColor3 = Color3.fromRGB(40, 40, 40);
						BackgroundTransparency = transparency;
						Size = UDim2.new(1, 0, 0, 1);
					};
				};
			};
		};
	}
end

return CommandPalette