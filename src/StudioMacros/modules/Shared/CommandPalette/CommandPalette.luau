local require = require(script.Parent.loader).load(script)

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local AccelTween = require("AccelTween")
local BasicPane = require("BasicPane")
local Blend = require("Blend")
local ButtonHighlightModel = require("ButtonHighlightModel")
local ColorEntry = require("ColorEntry")
local ColorPickerPane = require("ColorPickerPane")
local CommandGroup = require("CommandGroup")
local FontData = require("FontData")
local FontEntry = require("FontEntry")
local FontStyleEntry = require("FontStyleEntry")
local Fzy = require("Fzy")
local LipsumUtils = require("LipsumUtils")
local ObservableList = require("ObservableList")
local ObservableSortedList = require("ObservableSortedList")
local Rx = require("Rx")
local RxBrioUtils = require("RxBrioUtils")
local RxInstanceUtils = require("RxInstanceUtils")
local SearchUtils = require("SearchUtils")
local Signal = require("Signal")
local SpringObject = require("SpringObject")
local StepUtils = require("StepUtils")
local ValueObject = require("ValueObject")

local FZY_CONFIG = Fzy.createConfig()
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local KEY_DEBOUNCE = 0.05
local FOCUS_TIMEOUT = 1.5

local CommandPalette = setmetatable({}, BasicPane)
CommandPalette.ClassName = "CommandPalette"
CommandPalette.__index = CommandPalette

function CommandPalette.new()
	local self = setmetatable(BasicPane.new(), CommandPalette)

	self._groupMap = {}
	self._keysDown = {}
	self._lastKeyHandled = {}
	self._staleKeys = {}
	self._focusAttempt = 0
	self._pluginActive = false
	self._snapContainerHeight = false
	self._snapVisibility = false

	self._actionText = self._maid:Add(ValueObject.new("select a command..."))
	self._currentCustomResults = self._maid:Add(ValueObject.new(nil))
	self._customResultsEnabled = self._maid:Add(ValueObject.new(false))
	self._dockTarget = self._maid:Add(ValueObject.new(nil))
	self._entries = self._maid:Add(ObservableList.new())
	self._entriesOffset = self._maid:Add(ValueObject.new(0))
	self._entryHeight = self._maid:Add(ValueObject.new(45))
	self._fontPreviewText = self._maid:Add(ValueObject.new(""))
	self._inputFocused = self._maid:Add(ValueObject.new(false))
	self._percentAlphaValue = self._maid:Add(ValueObject.new(0, "number"))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0, "number"))
	self._primaryIcon = self._maid:Add(ValueObject.new("rbxassetid://6031154871"))
	self._primaryModel = self._maid:Add(ButtonHighlightModel.new())
	self._searchEntries = self._maid:Add(ObservableSortedList.new(true))
	self._searchQuery = self._maid:Add(ValueObject.new(""))
	self._secondaryModel = self._maid:Add(ButtonHighlightModel.new())
	self._selectedEntry = self._maid:Add(ValueObject.new(nil))
	self._selectedEntryIndex = self._maid:Add(ValueObject.new(0))
	self._selectedGroupEntryIndex = self._maid:Add(ValueObject.new(0))
	self._tabbed = self._maid:Add(Signal.new())
	self._targetEntryParent = self._maid:Add(ValueObject.new(nil))
	self._targetFont = self._maid:Add(ValueObject.new(nil))
	self._widgetRequested = self._maid:Add(ValueObject.new(false))

	self._percentVisible = self._maid:Add(SpringObject.new(self._percentVisibleTarget, 50, 0.9))
	self._percentVisible.Epsilon = 1e-3

	self._percentAlpha = AccelTween.new(2000)
	self._startAlphaAnimation, self._maid._stopAlphaAnimation = StepUtils.bindToRenderStep(function()
		self._percentAlphaValue.Value = self._percentAlpha.p
		return self._percentAlpha.rtime > 0
	end)

	self.CustomResultActivated = self._maid:Add(Signal.new())
	self.CustomResultsReset = self._maid:Add(Signal.new())
	self.TargetProperty = self._maid:Add(ValueObject.new(nil))
	self.TargetSelection = self._maid:Add(ValueObject.new(nil))

	self:_handleInput()
	self:_setupSearch()

	self._maid:GiveTask(function()
		self:_setPluginActive(false)
	end)

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible, doNotAnimate)
		self:_updatePluginActivation()

		table.clear(self._keysDown)

		if isVisible then
			self:_markStaleKeys()
		end

		if self._input then
			if isVisible then
				self:CaptureFocus()

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
				self.TargetSelection.Value = nil
				self:SetCustomResults(nil)
			end
		end

		self._primaryModel:SetInteractionEnabled(isVisible)
		self._secondaryModel:SetInteractionEnabled(isVisible)

		local percentVisible = isVisible and 1 or 0

		self._snapVisibility = doNotAnimate or false

		if isVisible and self._snapVisibility then
			self._snapContainerHeight = true
		end

		self._percentVisibleTarget.Value = percentVisible
		self._percentAlpha:SetTarget(percentVisible, doNotAnimate)

		if doNotAnimate then
			self._percentVisible.Position = percentVisible
			self._percentVisible.Velocity = 0
			self._percentAlphaValue.Value = percentVisible
		end

		self._startAlphaAnimation()
	end))

	return self
end

function CommandPalette:SetPlugin(plugin: Plugin)
	self._plugin = plugin

	self:_updatePluginActivation()
end

function CommandPalette:_updatePluginActivation()
	self:_setPluginActive(self:IsVisible() and not self:IsDocked())
end

function CommandPalette:_setPluginActive(isActive: boolean)
	if not self._plugin or isActive == self._pluginActive then
		return
	end

	self._pluginActive = isActive

	if isActive then
		self._plugin:Activate(true)
	else
		self._plugin:Deactivate()
	end
end

function CommandPalette:AddGroup(groupData)
	if not groupData then
		return
	end

	local groupEntry = self._maid:Add(CommandGroup.new())
	groupEntry:SetHeader(groupData.Name, groupData.Icon)

	table.insert(self._groupMap, groupEntry)

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

			if self._customResultsEnabled.Value and not entry.CustomResultType then
				return
			end

			local score = scoreBrio:GetValue()
			if score == nil or score < 0 then
				return
			end

			scoreBrio:ToMaid():GiveTask(self._searchEntries:Add(entry, entry.SearchScore:Observe()))
		end))
	end))

	return groupEntry
end

function CommandPalette:SetDockTarget(dockTarget: Instance?)
	if self._dockTarget.Value == dockTarget then
		return
	end

	table.clear(self._keysDown)

	self._dockTarget.Value = dockTarget

	if not dockTarget then
		self:_markStaleKeys()
	end

	self:_updatePluginActivation()
end

function CommandPalette:IsDocked(): boolean
	return self._dockTarget.Value ~= nil
end

function CommandPalette:ObserveCustomResults()
	return self._currentCustomResults:Observe()
end

function CommandPalette:ObserveWidgetRequested()
	return self._widgetRequested:Observe()
end

function CommandPalette:_tweenCanvasPosition(yPosition: number)
	if not self._entriesFrame then
		return
	end

	if self._scrollTween then
		self._scrollTween:Cancel()
		self._scrollTween = nil
	end

	local tween = TweenService:Create(self._entriesFrame, TWEEN_INFO, {
		CanvasPosition = Vector2.new(0, yPosition)
	})

	self._scrollTween = tween
	tween:Play()
end

function CommandPalette:_scrollToTop()
	if self._scrollTween then
		self._scrollTween:Cancel()
		self._scrollTween = nil
	end

	if self._entriesFrame then
		self._entriesFrame.CanvasPosition = Vector2.zero
	end
end

function CommandPalette:SetCustomResults(customResults: string, useWidget: boolean?)
	self._widgetRequested.Value = customResults ~= nil and useWidget == true

	if not customResults then
		self._actionText.Value = "select a command..."
		self._currentCustomResults.Value = nil
		self._customResultsEnabled.Value = false
		self._entriesOffset.Value = 0
		self._fontPreviewText.Value = ""
		self._primaryIcon.Value = "rbxassetid://6031154871"
		self._targetFont.Value = false
		self._primaryModel:SetIsChoosen(false)

		if self._lastSelectedEntryIndex then
			self._selectedEntryIndex.Value = self._lastSelectedEntryIndex
			self._lastSelectedEntryIndex = nil
		end

		if self:IsVisible() then
			task.defer(function()
				RunService.RenderStepped:Wait()
				self._input.Text = self._lastSearchQuery or ""
				self:CaptureFocus()
			end)
		end

		self.CustomResultsReset:Fire()

		return
	end

	self._lastSelectedEntryIndex = self._selectedEntryIndex.Value
	self._currentCustomResults.Value = customResults
	self._customResultsEnabled.Value = true
	self._input.Text = ""

	self:_scrollToTop()

	self._primaryIcon.Value = "rbxassetid://6031091000"
	self._primaryModel:SetIsChoosen(true)

	self:CaptureFocus()

	local selection = self.TargetSelection.Value

	if customResults == "Color" then
		if not self._colorEntries then
			self:_setupColorResults()
		end

		self._actionText.Value = "type any color (rgb, hex, color name)..."
	elseif customResults == "Font" then
		if not self._fontEntries or not self._fontStyleEntries then
			self:_setupFontResults()
		end

		self._actionText.Value = "type any font name..."

		if selection then
			local instance = selection[1]
			local text = ""

			if instance then
				if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
					text = instance.Text
				end
			end

			if text == "" then
				text = LipsumUtils.sentence(7)
			end

			self._fontPreviewText.Value = string.sub(text, 0, 90)
		end
	elseif customResults == "FontStyle" then
		if not self._fontEntries or not self._fontStyleEntries then
			self:_setupFontResults()
		end

		self._actionText.Value = "type any font style..."

		if selection then
			local instance = selection[1]

			if instance then
				if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
					self._targetFont.Value = instance.FontFace
				end
			end
		end
	end

	task.defer(function()
		self._selectedEntryIndex.Value = 0
	end)
end

function CommandPalette:_handleInput()
	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self._staleKeys[input.KeyCode] = nil
		end

		self:_handleKeyInput(input)
	end))
end

function CommandPalette:_markStaleKeys()
	table.clear(self._staleKeys)

	for _, inputObject in UserInputService:GetKeysPressed() do
		self._staleKeys[inputObject.KeyCode] = true
	end
end

function CommandPalette:_isKeyDown(keyCode: Enum.KeyCode): boolean
	local heldInput = self._keysDown[keyCode]
	if heldInput then
		if heldInput.UserInputState == Enum.UserInputState.End then
			self._keysDown[keyCode] = nil
		else
			return true
		end
	end

	if self:IsDocked() then
		return false
	end

	if self._staleKeys[keyCode] then
		return false
	end

	for _, inputObject in UserInputService:GetKeysPressed() do
		if inputObject.KeyCode == keyCode then
			return true
		end
	end

	return false
end

function CommandPalette:_handleCatcherInputBegan(input: InputObject)
	if input.UserInputType == Enum.UserInputType.Keyboard and self:IsDocked() then
		self._keysDown[input.KeyCode] = input
	end

	self:_handleKeyInput(input)
end

function CommandPalette:_handleCatcherInputEnded(input: InputObject)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		self._keysDown[input.KeyCode] = nil
	end
end

function CommandPalette:_shouldHandleKey(keyCode: Enum.KeyCode): boolean
	local now = os.clock()
	local lastHandled = self._lastKeyHandled[keyCode]

	if lastHandled and now - lastHandled < KEY_DEBOUNCE then
		return false
	end

	self._lastKeyHandled[keyCode] = now

	return true
end

local function isTypingKey(keyCode: Enum.KeyCode): boolean
	local value = keyCode.Value

	return (value >= 97 and value <= 122) or (value >= 48 and value <= 57) or value == 32
end

function CommandPalette:_handleKeyInput(input: InputObject)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if not self._input then
		return
	end

	if self:IsVisible() and isTypingKey(input.KeyCode) and not self._input:IsFocused() then
		local focusedTextBox = UserInputService:GetFocusedTextBox()

		if not focusedTextBox and self._input.Visible then
			self._input:CaptureFocus()
		end
	end

	local keyCode = input.KeyCode
	if not self:_shouldHandleKey(keyCode) then
		return
	end

	local ctrlPressed = self:_isKeyDown(Enum.KeyCode.LeftControl) or self:_isKeyDown(Enum.KeyCode.RightControl)
	local shiftPressed = self:_isKeyDown(Enum.KeyCode.LeftShift) or self:_isKeyDown(Enum.KeyCode.RightShift)

	local upPressed = keyCode == Enum.KeyCode.Up
	local downPressed = keyCode == Enum.KeyCode.Down

	if keyCode == Enum.KeyCode.Tab then
		self:_handleTab()
	end

	if ctrlPressed then
		if keyCode == Enum.KeyCode.J then
			downPressed = true
		elseif keyCode == Enum.KeyCode.K then
			upPressed = true
		elseif keyCode == Enum.KeyCode.D then
			self._entryHeight.Value = self._entryHeight.Value == 45 and 30 or 45
			self._secondaryModel:SetKeyDown(true)

			self._maid:GiveTask(task.delay(0.1, function()
				self._secondaryModel:SetKeyDown(false)
			end))
		end
	end

	if keyCode == Enum.KeyCode.Escape then
		self:_handleEscape(shiftPressed)
	elseif upPressed or downPressed then
		self:_handleNavigation(upPressed, downPressed)
	end
end

function CommandPalette:_handleTab()
	if not self._inputFocused.Value then
		return
	end

	self._tabbed:Fire()

	task.spawn(function()
		RunService.RenderStepped:Wait()

		if self._input then
			self._input.Text = (string.gsub(self._input.Text, "\t", ""))
		end
	end)
end

function CommandPalette:_handleEscape(shiftPressed: boolean)
	if shiftPressed and self._input:IsFocused() then
		self._input:ReleaseFocus()
		return
	end

	if self._input.Text ~= "" then
		self._input.Text = ""
		self:CaptureFocus()
		return
	end

	if self._customResultsEnabled.Value and not self:IsDocked() then
		self._primaryModel:SetKeyDown(true)

		self._maid:GiveTask(task.delay(0.1, function()
			self._primaryModel:SetKeyDown(false)
		end))

		self:SetCustomResults(nil)
		return
	end

	self:Hide()
end

function CommandPalette:_handleNavigation(upPressed: boolean, downPressed: boolean)
	if self._searchQuery.Value ~= "" then
		self._selectedGroupEntryIndex.Value = 0

		local count = #self._searchEntries:GetList()
		local selectedEntryIndex = math.clamp(self._selectedEntryIndex.Value, 1, math.max(count, 1))

		if upPressed and selectedEntryIndex - 1 > 0 then
			self._selectedEntryIndex.Value = selectedEntryIndex - 1
		elseif downPressed and selectedEntryIndex + 1 <= count then
			self._selectedEntryIndex.Value = selectedEntryIndex + 1
		else
			self._selectedEntryIndex.Value = selectedEntryIndex
		end

		return
	end

	local customResultsEnabled = self._customResultsEnabled.Value

	local selectedEntry = self._selectedEntryIndex.Value
	local selectedGroup = self._selectedGroupEntryIndex.Value
	local groupEntries = self._groupMap

	local currentGroup
	local currentGroupEntries

	if not customResultsEnabled then
		if selectedGroup == 0 and selectedEntry == 0 then
			if upPressed then
				-- self._selectedGroupEntryIndex.Value = #groupEntries
			else
				self._selectedGroupEntryIndex.Value += 1
			end
			return
		end

		currentGroup = groupEntries[selectedGroup]
		if not currentGroup then
			return
		end

		currentGroupEntries = #currentGroup:GetEntries() - 1
	else
		local customResultType = self._currentCustomResults.Value
		local customEntries

		if customResultType == "Color" then
			customEntries = self._colorEntries
		elseif customResultType == "Font" then
			customEntries = self._fontEntries
		elseif customResultType == "FontStyle" then
			customEntries = self._fontStyleEntries
		end

		if not customEntries or #customEntries == 0 then
			return
		end

		currentGroupEntries = #customEntries - 1
	end

	if upPressed then
		if not customResultsEnabled then
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
			if selectedEntry - 1 >= 0 then
				self._selectedEntryIndex.Value -= 1
			end
		end
	else
		if not customResultsEnabled then
			if selectedEntry + 1 <= currentGroupEntries and not currentGroup:IsCollapsed() then
				self._selectedEntryIndex.Value += 1
			elseif ((selectedEntry + 1 > currentGroupEntries) or currentGroup:IsCollapsed()) and selectedGroup + 1 <= #groupEntries then
				self._selectedEntryIndex.Value = 0
				self._selectedGroupEntryIndex.Value += 1
			end
		else
			if selectedEntry + 1 <= currentGroupEntries then
				self._selectedEntryIndex.Value += 1
			end
		end
	end
end

function CommandPalette:_setupSearch()
	self._maid:GiveTask(Rx.combineLatest({
		CurrentEntry = self._selectedEntryIndex:Observe();
		CurrentGroup = self._selectedGroupEntryIndex:Observe();
		CustomResultType = self._currentCustomResults:Observe();
		CustomResultsEnabled = self._customResultsEnabled:Observe();
		SearchCount = self._searchEntries:ObserveCount();
		SearchQuery = self._searchQuery:Observe();
	}):Pipe({
		Rx.switchMap(function(data)
			if data.SearchQuery ~= "" then
				if data.SearchCount == 0 then
					return Rx.of(nil)
				end

				local index = math.clamp(data.CurrentEntry, 1, data.SearchCount)

				return self._searchEntries:ObserveAtIndex(index)
			end

			local currentEntries

			if not data.CustomResultsEnabled then
				if data.CurrentGroup == 0 then
					return Rx.EMPTY
				end

				local groupEntries = self._entries:GetList()
				local currentGroup = groupEntries[data.CurrentGroup]

				if not currentGroup then
					return Rx.EMPTY
				end

				currentEntries = currentGroup:GetEntries()
			else
				if data.CustomResultType == "Color" then
					currentEntries = self._colorEntries
				elseif data.CustomResultType == "Font" then
					currentEntries = self._fontEntries
				elseif data.CustomResultType == "FontStyle" then
					currentEntries = self._fontStyleEntries
				end
			end

			if not currentEntries then
				return Rx.EMPTY
			end

			if data.CurrentEntry == 0 then
				return Rx.of(currentEntries[1])
			end

			return Rx.of(currentEntries[data.CurrentEntry + 1])
		end);
	}):Subscribe(function(entry)
		self._selectedEntry.Value = entry
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
end

function CommandPalette:_setupColorResults()
	if self._colorEntries then
		return
	end

	self._colorEntries = {}

	local sortedEntries = {}
	local colorPickerPane = self._maid:Add(ColorPickerPane.new())

	self._colorPicker = colorPickerPane
	if self._bodyFrame then
		self._colorPicker:SetTargetParent(self._bodyFrame)
	end

	self._maid:GiveTask(colorPickerPane.TabReturned:Connect(function()
		self:CaptureFocus()
	end))

	self._maid:GiveTask(self._dockTarget:Observe():Subscribe(function(dockTarget)
		colorPickerPane:SetPluginGui(dockTarget)
	end))

	self._maid:GiveTask(self._currentCustomResults:ObserveBrio():Subscribe(function(customResultsBrio)
		if customResultsBrio:IsDead() then
			return
		end

		local maid, customResults = customResultsBrio:ToMaidAndValue()
		if customResults ~= "Color" then
			return
		end

		local initialSelection = self.TargetSelection.Value
		if not initialSelection or #initialSelection == 0 then
			return
		end

		local targetProperty = self.TargetProperty.Value
		if not targetProperty then
			return
		end

		local function resolveProperty(instance)
			if type(targetProperty) == "function" then
				return targetProperty(instance)
			end

			return targetProperty
		end

		local function readColor(instance)
			local property = resolveProperty(instance)
			if not property then
				return nil
			end

			local success, value = pcall(function()
				return instance[property]
			end)

			if not success or typeof(value) ~= "Color3" then
				return nil
			end

			return value
		end

		local seedInstance
		for _, instance in initialSelection do
			if readColor(instance) then
				seedInstance = instance
				break
			end
		end

		if not seedInstance then
			return
		end

		colorPickerPane:SetColor(readColor(seedInstance))

		-- Undo/redo support
		maid:GiveTask(ChangeHistoryService.OnUndo:Connect(function()
			colorPickerPane:SetColor(readColor(seedInstance))
		end))

		maid:GiveTask(ChangeHistoryService.OnRedo:Connect(function()
			colorPickerPane:SetColor(readColor(seedInstance))
		end))

		maid:GiveTask(colorPickerPane:ObserveColor():Subscribe(function(newColor)
			if not newColor then
				return
			end

			for _, instance in initialSelection do
				local current = readColor(instance)
				if current and current ~= newColor then
					instance[resolveProperty(instance)] = newColor
				end
			end
		end))

		-- Since we don't want to spam the undo stack as they're picking a
		-- color, we only want to fire the macro when the user stops dragging
		maid:GiveTask(colorPickerPane.ColorUpdated:Connect(function(newColor)
			self.CustomResultActivated:Fire("Color", true, newColor)
		end))
	end))

	local function createColorEntry(i)
		local brickColor = BrickColor.new(i)
		if brickColor.Name == "Medium stone grey" and i ~= 194 then
			return
		end

		local entry = self._maid:Add(ColorEntry.new())
		entry:SetColorName(brickColor.Name)
		entry:SetColor(brickColor.Color)

		table.insert(sortedEntries, entry)

		self._maid:GiveTask(entry.Activated:Connect(function(shiftPressed)
			colorPickerPane:SetColor(brickColor.Color)
			self.CustomResultActivated:Fire("Color", shiftPressed, brickColor.Color)
		end))
	end

	-- from https://create.roblox.com/docs/reference/engine/datatypes/BrickColor
	for i = 1, 50 do
		createColorEntry(i)
	end

	for i = 100, 365 do
		createColorEntry(i)
	end

	for i = 1001, 1032 do
		createColorEntry(i)
	end

	table.sort(sortedEntries, function(a, b)
		local aH, aS, aV = a.Color.Value:ToHSV()
		local bH, bS, bV = b.Color.Value:ToHSV()

		if aH ~= bH then
			return aH < bH
		elseif aS ~= bS then
			return aS < bS
		else
			return aV < bV
		end
	end)

	self._maid:GiveTask(self._entries:Add(colorPickerPane))

	for index, entry in sortedEntries do
		entry:SetDefaultIndex(index)
		table.insert(self._colorEntries, entry)
		self._maid:GiveTask(self._entries:Add(entry))

		self._maid:GiveTask(entry.SearchScore:ObserveBrio():Subscribe(function(scoreBrio)
			if scoreBrio:IsDead() then
				return
			end

			if not self._customResultsEnabled.Value then
				return
			elseif entry.CustomResultType ~= self._currentCustomResults.Value then
				return
			end

			local score = scoreBrio:GetValue()
			if score == nil or score < 0 then
				return
			end

			scoreBrio:ToMaid():GiveTask(self._searchEntries:Add(entry, entry.SearchScore:Observe()))
		end))
	end

	self._maid:GiveTask(Blend.Computed(self._customResultsEnabled, self._currentCustomResults, function(isEnabled, resultsType)
		local isVisible = false
		if isEnabled and resultsType == "Color" then
			isVisible = true
		end

		colorPickerPane:SetVisible(isVisible)
		for _, entry in self._colorEntries do
			entry:SetVisible(isVisible)
		end
	end):Subscribe())
end

function CommandPalette:_setupFontResults()
	if self._fontEntries then
		return
	end

	self._fontEntries = {}
	self._fontStyleEntries = {}

	local sortedFontEntries = {}
	local sortedFontStyleEntries = {}
	local styleEntryMap = {}

	for fontId, data in FontData do
		local newFont
		if typeof(fontId) == "number" then
			newFont = Font.fromId(fontId)
		elseif typeof(fontId) == "string" then
			newFont = Font.new(fontId)
		end

		local fontNameEntry = self._maid:Add(FontEntry.new())
		fontNameEntry:SetFontName(data.Name)
		fontNameEntry:SetStyleCount(#data.Styles)
		fontNameEntry.Font.Value = newFont

		for _, style in data.Styles do
			local isItalic = string.find(style, "Italic") and true or false
			local styleEntry = styleEntryMap[style]

			if not styleEntry then
				styleEntry = self._maid:Add(FontStyleEntry.new())
				styleEntry:SetIsItalic(isItalic)
				styleEntry:SetStyleName(style)

				table.insert(sortedFontStyleEntries, styleEntry)
				styleEntryMap[style] = styleEntry

				self._maid:GiveTask(styleEntry.Activated:Connect(function(shiftPressed)
					self.CustomResultActivated:Fire("FontStyle", shiftPressed, styleEntry:GetData())
				end))
			end

			styleEntry:SetFontCompatible(newFont)
		end

		self._maid:GiveTask(fontNameEntry.Activated:Connect(function(shiftPressed)
			self.CustomResultActivated:Fire("Font", shiftPressed, fontNameEntry.Font.Value)
		end))

		table.insert(sortedFontEntries, fontNameEntry)
	end

	table.sort(sortedFontEntries, function(a, b)
		local aFontName = a:GetFontName()
		local bFontName = b:GetFontName()

		return aFontName < bFontName
	end)

	table.sort(sortedFontStyleEntries, function(a, b)
		local aFontWeight = a:GetFontWeight()
		local bFontWeight = b:GetFontWeight()

		return aFontWeight < bFontWeight
	end)

	for index, entry in sortedFontEntries do
		entry:SetDefaultIndex(index)
		table.insert(self._fontEntries, entry)
		self._maid:GiveTask(self._entries:Add(entry))

		self._maid:GiveTask(entry.SearchScore:ObserveBrio():Subscribe(function(scoreBrio)
			if scoreBrio:IsDead() then
				return
			end

			if not self._customResultsEnabled.Value then
				return
			elseif entry.CustomResultType ~= self._currentCustomResults.Value then
				return
			end

			local score = scoreBrio:GetValue()
			if score == nil or score < 0 then
				return
			end

			scoreBrio:ToMaid():GiveTask(self._searchEntries:Add(entry, entry.SearchScore:Observe()))
		end))
	end

	for index, entry in sortedFontStyleEntries do
		entry:SetDefaultIndex(index)
		table.insert(self._fontStyleEntries, entry)
		self._maid:GiveTask(self._entries:Add(entry))

		self._maid:GiveTask(entry.SearchScore:ObserveBrio():Subscribe(function(scoreBrio)
			if scoreBrio:IsDead() then
				return
			end

			if not self._customResultsEnabled.Value then
				return
			elseif entry.CustomResultType ~= self._currentCustomResults.Value then
				return
			end

			local targetFont = self._targetFont.Value
			if not targetFont or not entry:IsFontCompatible(targetFont) then
				return
			end

			local score = scoreBrio:GetValue()
			if score == nil or score < 0 then
				return
			end

			scoreBrio:ToMaid():GiveTask(self._searchEntries:Add(entry, entry.SearchScore:Observe()))
		end))
	end

	self._maid:GiveTask(Blend.Computed(self._customResultsEnabled, self._currentCustomResults, function(isEnabled, resultsType)
		local isVisible = false
		if isEnabled then
			isVisible = true
		end

		if resultsType == "Font" then
			for _, entry in self._fontEntries do
				entry:SetVisible(isVisible)
			end
		elseif resultsType == "FontStyle" then
			for _, entry in self._fontStyleEntries do
				entry:SetVisible(isVisible)
			end
		end
	end):Subscribe())
end

function CommandPalette:CaptureFocus()
	if not self._input then
		return
	end

	self._focusAttempt += 1

	local attempt = self._focusAttempt

	task.defer(function()
		local deadline = os.clock() + FOCUS_TIMEOUT

		while true do
			RunService.RenderStepped:Wait()

			if attempt ~= self._focusAttempt or not self._input then
				return
			end

			if not self:IsVisible() then
				return
			end

			if self._input:IsFocused() then
				return
			end

			local focusedTextBox = UserInputService:GetFocusedTextBox()
			if focusedTextBox and focusedTextBox ~= self._input then
				return
			end

			if self._input.Visible then
				self._input:CaptureFocus()
			end

			if os.clock() >= deadline then
				return
			end
		end
	end)
end

function CommandPalette:Render(props)
	local percentVisible = self._percentVisible:Observe()
	local percentAlpha = self._percentAlphaValue:Observe()

	local revealedCount = 0
	local lastEntryCount = 0

	self._maid:GiveTask(Blend.Computed(percentAlpha, function(percent)
		local entries = self._entries:GetList()
		local entryCount = #entries
		local divisor = math.max(1, entryCount)

		local target = math.clamp(math.floor((percent - 1e-1) * divisor) + 1, 0, entryCount)
		local doNotAnimate = self._snapVisibility

		if entryCount ~= lastEntryCount then
			lastEntryCount = entryCount

			for index, entry in entries do
				entry:SetVisible(index <= target, doNotAnimate)
			end

			revealedCount = target
			return
		end

		if target > revealedCount then
			for index = revealedCount + 1, target do
				entries[index]:SetVisible(true, doNotAnimate)
			end
		elseif target < revealedCount then
			for index = revealedCount, target + 1, -1 do
				entries[index]:SetVisible(false, doNotAnimate)
			end
		end

		revealedCount = target
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

	local containerTarget = Blend.Computed(contentHeight, windowHeight, function(content, window)
		return math.min(content + 92, window)
	end)

	local containerSpring = self._maid:Add(SpringObject.new(0, 30, 1))
	containerSpring.Epsilon = 1e-3

	self._maid:GiveTask(Blend.Computed(containerTarget, function(height)
		containerSpring.Target = height

		if self._snapContainerHeight then
			containerSpring.Position = height
			containerSpring.Velocity = 0
			self._snapContainerHeight = contentHeight.Value <= 0
		end
	end):Subscribe())

	local containerPercent = containerSpring:Observe()

	local layoutSettled = Blend.Computed(percentVisible, containerPercent, containerTarget, function(percent, container, target)
		return percent > 0.99 and math.abs(container - target) < 1
	end)

	self._maid:GiveTask(Blend.Computed(self._selectedEntry, layoutSettled, function(entry, isSettled)
		if not self._entriesFrame or not isSettled then
			return
		end

		if entry then
			local canvasPosition = self._entriesFrame.CanvasPosition.Y
			local framePosition = self._entriesFrame.AbsolutePosition.Y
			local frameSize = self._entriesFrame.AbsoluteSize.Y

			local entryPosition = entry:GetYPosition() - framePosition
			local entrySize = self._entryHeight.Value

			local customResults = self._currentCustomResults.Value
			if customResults == "Font" or customResults == "FontStyle" then
				entrySize = entrySize == 45 and 60 or 40
			end

			local entryBottom = entryPosition + entrySize
			local newCanvasPosition = canvasPosition

			if entryBottom > frameSize then
				newCanvasPosition += entryBottom - frameSize + 1
			elseif entryPosition < 0 then
				newCanvasPosition += entryPosition
			end

			if newCanvasPosition ~= canvasPosition then
				self:_tweenCanvasPosition(newCanvasPosition)
			end
		end
	end):Subscribe())

	local buttonVisible = Blend.Computed(percentVisible, function(percent)
		return percent > 0.01
	end)

	local primaryPercentHighlighted = Blend.AccelTween(self._primaryModel:ObservePercentHighlightedTarget(), 400)
	local primaryPercentPressed = Blend.Spring(self._primaryModel:ObservePercentPressedTarget(), 40, 0.8)
	local primaryPercentSelected = Blend.Spring(self._primaryModel:ObservePercentChoosenTarget(), 40, 0.8)
	local secondaryPercentHighlighted = Blend.AccelTween(self._secondaryModel:ObservePercentHighlightedTarget(), 400)
	local secondaryPercentPressed = Blend.Spring(self._secondaryModel:ObservePercentPressedTarget(), 40, 0.8)

	local isDocked = Blend.Computed(self._dockTarget, function(dockTarget)
		return dockTarget ~= nil
	end)

	local defaultParent = (props and props.Parent) or false

	return Blend.New "Frame" {
		Name = "CommandPalette";
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundColor3 = Color3.fromRGB(30, 30, 30);
		Position = UDim2.fromScale(0.5, 0.5);

		Parent = Blend.Computed(self._dockTarget, defaultParent, function(dockTarget, parent)
			return dockTarget or parent or nil
		end);

		Size = Blend.Computed(isDocked, function(docked)
			return docked and UDim2.fromScale(1, 1) or UDim2.fromScale(0.4, 0.75)
		end);

		BackgroundTransparency = Blend.Computed(isDocked, transparency, function(docked, percent)
			return docked and percent or 1
		end);

		[Blend.OnChange "AbsoluteSize"] = function(windowSize)
			windowHeight.Value = math.round(windowSize.Y) - 90
		end;

		Active = Blend.Computed(isDocked, self:ObserveVisible(), function(docked, isVisible)
			return docked or isVisible
		end);

		[Blend.OnEvent "InputBegan"] = function(input)
			self:_handleCatcherInputBegan(input)
		end;

		[Blend.OnEvent "InputEnded"] = function(input)
			self:_handleCatcherInputEnded(input)
		end;

		Blend.New "UISizeConstraint" {
			MinSize = Blend.Computed(isDocked, function(docked)
				return docked and Vector2.zero or Vector2.new(650, 0)
			end);
		};

		Blend.New "Frame" {
			Name = "keyCatcher";
			Active = true;
			BackgroundTransparency = 1;
			Selectable = false;
			Size = UDim2.fromScale(1, 1);
			Visible = isDocked;
			ZIndex = -100;

			[Blend.OnEvent "InputBegan"] = function(input)
				self:_handleCatcherInputBegan(input)
			end;

			[Blend.OnEvent "InputEnded"] = function(input)
				self:_handleCatcherInputEnded(input)
			end;
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

				Visible = Blend.Computed(isDocked, function(docked)
					return not docked
				end);

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

						Blend.New "TextButton" {
							Name = "primaryAction";
							AnchorPoint = Vector2.new(1, 0.5);
							BackgroundColor3 = Color3.fromRGB(40, 40, 40);
							Interactable = self._customResultsEnabled;
							LayoutOrder = 1;
							Position = UDim2.fromScale(1, 0);
							Size = UDim2.new(1, 5, 1, 5);
							Text = "";
							Visible = buttonVisible;
							ZIndex = 5;

							BackgroundTransparency = Blend.Computed(transparency, primaryPercentHighlighted, primaryPercentSelected, function(percent, percentHighlight, percentSelected)
								return 1 - percentHighlight + percent - percentSelected
							end);

							[Blend.OnEvent "Activated"] = function()
								if self._customResultsEnabled.Value then
									self:SetCustomResults(nil)
								end
							end;

							[Blend.Instance] = function(button)
								self._primaryModel:SetButton(button)
							end;

							Blend.New "UIAspectRatioConstraint" {
								AspectRatio = 1;
							};

							Blend.New "UICorner" {
								CornerRadius = UDim.new(0, 5);
							};

							Blend.New "ImageLabel" {
								Name = "icon";
								AnchorPoint = Vector2.new(0.5, 0.5);
								BackgroundTransparency = 1;
								Image = self._primaryIcon;
								ImageTransparency = transparency;
								Position = UDim2.fromScale(0.5, 0.5);
								Size = UDim2.fromScale(1, 1);

								ImageColor3 = Blend.Computed(primaryPercentHighlighted, function(percentHighlight)
									return Color3.fromRGB(75, 75, 75):Lerp(Color3.fromRGB(150, 150, 150), percentHighlight)
								end);

								Blend.New "UIScale" {
									Scale = Blend.Computed(primaryPercentPressed, function(percent)
										return 1 - (percent * 0.15)
									end);
								};
							};

							Blend.New "UIPadding" {
								PaddingBottom = UDim.new(0, 3);
								PaddingLeft = UDim.new(0, 3);
								PaddingRight = UDim.new(0, 3);
								PaddingTop = UDim.new(0, 3);
							};
						};
						Blend.New "TextBox" {
							Name = "input";
							BackgroundTransparency = 1;
							ClearTextOnFocus = false;
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json");
							LayoutOrder = 2;
							PlaceholderColor3 = Color3.fromRGB(80, 80, 80);
							PlaceholderText = self._actionText;
							Position = UDim2.fromScale(0.04, 0);
							Size = UDim2.fromScale(0.9, 1);
							TextColor3 = Color3.fromRGB(220, 220, 220);
							TextSize = 15;
							TextTransparency = transparency;
							TextXAlignment = Enum.TextXAlignment.Left;
							Visible = buttonVisible;

							Blend.New "UITextSizeConstraint" {
								MaxTextSize = 16;
							};

							[Blend.Instance] = function(input)
								self._input = input
							end;

							[Blend.OnChange "Text"] = function(text)
								if string.find(text, "\t", 1, true) then
									self._input.Text = (string.gsub(text, "\t", ""))

									if self:_shouldHandleKey(Enum.KeyCode.Tab) then
										self:_handleTab()
									end

									return
								end

								local strippedText = string.gsub(text, "[\r\n]", "")

								if strippedText ~= text then
									local cursorPosition = self._input.CursorPosition
									self._input.Text = strippedText

									if cursorPosition > 0 then
										self._input.CursorPosition = math.clamp(cursorPosition - (#text - #strippedText), 1, #strippedText + 1)
									end

									return
								end

								local safeText = string.gsub(text, "%s+", " ")

								if safeText == " " then
									safeText = ""
								end

								if self._customResultsEnabled.Value then
									if not self._lastSearchQuery then
										self._lastSearchQuery = self._searchQuery.Value
									end
								else
									self._lastSearchQuery = nil
								end

								local queryChanged = safeText ~= self._searchQuery.Value

								self._searchQuery.Value = safeText

								if queryChanged and #self._entries:GetList() > 0 then
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

							[Blend.OnEvent "FocusLost"] = function(enterPressed, inputObject)
								local selectedEntry = self._selectedEntry.Value
								local refocusInput = false

								-- Hold shift to trigger without closing the palette
								local shiftPressed = self:_isKeyDown(Enum.KeyCode.LeftShift)
									or self:_isKeyDown(Enum.KeyCode.RightShift)

								local keyCode = inputObject and inputObject.KeyCode
								local escapePressed = keyCode == Enum.KeyCode.Escape
									or (keyCode == nil and not enterPressed and self:_isKeyDown(Enum.KeyCode.Escape))
								local tabPressed = keyCode == Enum.KeyCode.Tab
									or (keyCode == nil and not enterPressed and self:_isKeyDown(Enum.KeyCode.Tab))

								if tabPressed and not escapePressed then
									self._inputFocused.Value = false
									return
								end

								if escapePressed then
									if shiftPressed then
										self._inputFocused.Value = false
										return
									end

									if self:_shouldHandleKey(Enum.KeyCode.Escape) then
										self:_handleEscape(false)
									end
								elseif shiftPressed then
									refocusInput = true
								end

								if enterPressed and selectedEntry then
									if not selectedEntry.CustomResultType and selectedEntry:IsGroupHeader() then
										local selectedGroup = self._selectedGroupEntryIndex.Value
										local groupEntry = self._entries:GetList()[selectedGroup]

										if not groupEntry then
											return
										end

										groupEntry:SetIsCollapsed(not groupEntry:IsCollapsed())
										refocusInput = true
									else
										selectedEntry.Activated:Fire(shiftPressed)
									end
								elseif enterPressed then
									if self._customResultsEnabled.Value then
										local customResultsType = self._currentCustomResults.Value
										if customResultsType == "Color" then
											local currentText = self._input.Text
											if SearchUtils.stringIsRGB(currentText) then
												local _, r, g, b = SearchUtils.stringIsRGB(currentText)
												local newColor = Color3.fromRGB(r, g, b)
												if self._colorPicker then
													self._colorPicker:SetColor(newColor)
												end
												self.CustomResultActivated:Fire("Color", shiftPressed, newColor)
											elseif SearchUtils.stringIsHex(currentText) then
												local _, hex = SearchUtils.stringIsHex(currentText)
												local newColor = Color3.fromHex(hex)
												if self._colorPicker then
													self._colorPicker:SetColor(newColor)
												end
												self.CustomResultActivated:Fire("Color", shiftPressed, newColor)
											end
										end
									end
								end

								if refocusInput then
									self:CaptureFocus()
								else
									self._inputFocused.Value = false
								end
							end;
						};

						Blend.New "TextButton" {
							Name = "secondaryAction";
							AnchorPoint = Vector2.new(1, 0.5);
							BackgroundColor3 = Color3.fromRGB(40, 40, 40);
							LayoutOrder = 3;
							Position = UDim2.fromScale(1, 0);
							Size = UDim2.new(1, 5, 1, 5);
							Text = "";
							Visible = buttonVisible;
							ZIndex = 5;

							BackgroundTransparency = Blend.Computed(transparency, secondaryPercentHighlighted, function(percent, percentHighlight)
								return 1 - percentHighlight + percent
							end);

							[Blend.OnEvent "Activated"] = function()
								self._entryHeight.Value = self._entryHeight.Value == 45 and 30 or 45
							end;

							[Blend.Instance] = function(button)
								self._secondaryModel:SetButton(button)
							end;

							Blend.New "UIAspectRatioConstraint" {
								AspectRatio = 1;
							};

							Blend.New "UICorner" {
								CornerRadius = UDim.new(0, 5);
							};

							Blend.New "ImageLabel" {
								Name = "icon";
								AnchorPoint = Vector2.new(0.5, 0.5);
								BackgroundTransparency = 1;
								Image = "rbxassetid://6022668888";
								ImageTransparency = transparency;
								Position = UDim2.fromScale(0.5, 0.5);
								Size = UDim2.fromScale(1, 1);

								ImageColor3 = Blend.Computed(secondaryPercentHighlighted, function(percentHighlight)
									return Color3.fromRGB(75, 75, 75):Lerp(Color3.fromRGB(150, 150, 150), percentHighlight)
								end);

								Blend.New "UIScale" {
									Scale = Blend.Computed(secondaryPercentPressed, function(percent)
										return 1 - (percent * 0.15)
									end);
								};
							};

							Blend.New "UIPadding" {
								PaddingBottom = UDim.new(0, 3);
								PaddingLeft = UDim.new(0, 3);
								PaddingRight = UDim.new(0, 3);
								PaddingTop = UDim.new(0, 3);
							};
						};
					};

					Blend.New "TextButton" {
						Name = "button";
						BackgroundTransparency = 1;
						ZIndex = 5;

						Position = Blend.Computed(self._inputFocused, self._customResultsEnabled, function(isFocused, customResults)
							if isFocused or customResults then
								return UDim2.new(0, 35, 0, 0)
							else
								return UDim2.fromOffset(0, 0)
							end
						end);

						Size = Blend.Computed(self._inputFocused, self._customResultsEnabled, function(isFocused, customResults)
							local leftInset = (isFocused or customResults) and 35 or 0

							return UDim2.new(1, -(leftInset + 35), 1, 0)
						end);

						Visible = Blend.Computed(self:ObserveVisible(), self._inputFocused, function(isVisible, isFocused)
							if not isVisible then
								return false
							else
								return not isFocused
							end
						end);

						[Blend.OnEvent "Activated"] = function()
							self:CaptureFocus()
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

					[Blend.Instance] = function(frame)
						self._bodyFrame = frame
					end;

					Blend.New "ScrollingFrame" {
						Name = "entries";
						Active = true;
						BackgroundTransparency = 1;
						ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50);
						ScrollBarImageTransparency = transparency;
						ScrollingDirection = Enum.ScrollingDirection.Y;
						ScrollingEnabled = self:ObserveVisible();
						VerticalScrollBarInset = Enum.ScrollBarInset.Always;
						Visible = buttonVisible;

						CanvasSize = Blend.Computed(contentHeight, self._entriesOffset, function(contentHeight, offset)
							return UDim2.fromOffset(0, contentHeight + 2 - offset);
						end);

						Position = Blend.Computed(self._entriesOffset, function(offset)
							return UDim2.fromOffset(0, offset)
						end);

						Size = Blend.Computed(self._entriesOffset, function(offset)
							return UDim2.new(1, 0, 1, -offset)
						end);

						ScrollBarThickness = Blend.Computed(percentScrollThickness, function(percent)
							return 10 * percent
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

								contentHeight.Value = math.round(size.Y) + self._entriesOffset.Value
							end;
						};

						self._entries:ObserveItemsBrio():Pipe({
							RxBrioUtils.map(function(groupEntry)
								return groupEntry:Render({
									CustomResult = self._currentCustomResults;
									EntryHeight = self._entryHeight;
									FontPreviewText = self._fontPreviewText;
									FzyConfig = FZY_CONFIG;
									SearchQuery = self._searchQuery;
									Tabbed = self._tabbed;
									Transparency = transparency;
									TargetFont = self._targetFont;

									Enabled = Blend.Computed(self._customResultsEnabled, self._currentCustomResults, function(isEnabled, customResults)
										if customResults and groupEntry.CustomResultType == customResults then
											return isEnabled
										else
											return not isEnabled
										end
									end);

									TargetParent = Blend.Computed(self._targetEntryParent, self._customResultsEnabled, self._currentCustomResults, function(targetParent, isEnabled, customResultType)
										if groupEntry.CustomResultType then
											if isEnabled then
												if customResultType == groupEntry.CustomResultType then
													if groupEntry.Pinned then
														self._entriesOffset.Value = groupEntry.Height or 0
														groupEntry:SetTargetParent(self._bodyFrame)
														return self._bodyFrame
													else
														return self._entriesFrame
													end
												else
													return nil
												end
											else
												return nil
											end
										else
											return not isEnabled and targetParent or nil
										end
									end);
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