local require = require(script.Parent.loader).load(script)

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local ChangeSizePane = require("ChangeSizePane")
local ExpressionUtils = require("ExpressionUtils")
local Maid = require("Maid")
local getChangeSizeVariables = require("getChangeSizeVariables")

local COMPONENT_KEYS = { "XScale", "XOffset", "YScale", "YOffset" }
local WIDGET_ID = "StudioMacros_ChangeSize"

local ChangeSizeWidget = {}
ChangeSizeWidget.ClassName = "ChangeSizeWidget"
ChangeSizeWidget.__index = ChangeSizeWidget

local instance = nil

function ChangeSizeWidget.get(plugin: Plugin)
	if not instance then
		instance = ChangeSizeWidget.new(plugin)
	end

	return instance
end

function ChangeSizeWidget.new(plugin: Plugin)
	local self = setmetatable({}, ChangeSizeWidget)

	self._maid = Maid.new()
	self._lastFocusIndex = 1
	self._plugin = plugin
	self._targets = {}
	self._windowFocused = false

	local widget = plugin:CreateDockWidgetPluginGui(WIDGET_ID, DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		true,
		560,
		150,
		420,
		130
	))

	widget.Name = "StudioMacrosChangeSize"
	widget.Title = "change size"
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	widget.Enabled = false

	self._maid:GiveTask(widget)
	self._widget = widget

	local pane = self._maid:Add(ChangeSizePane.new())
	self._pane = pane

	self._maid:GiveTask(pane:Render({ Parent = widget }):Subscribe())

	self._maid:GiveTask(pane.Submitted:Connect(function(values)
		self:_apply(values)
	end))

	self._maid:GiveTask(pane.Cancelled:Connect(function()
		self:Close()
	end))

	for index, fieldName in ChangeSizePane.getFieldNames() do
		local action = plugin:CreatePluginAction(
			`Change Size: Focus {fieldName}`,
			`Change Size: Focus {fieldName}`,
			`[StudioMacros]: Focus the {fieldName} input in the change size window, opening it if it isn't already (bind this to Ctrl+{index}).`,
			"rbxassetid://5972593639",
			true
		)

		self._maid:GiveTask(action.Triggered:Connect(function()
			self:FocusField(index)
		end))
	end

	self._maid:GiveTask(widget.WindowFocused:Connect(function()
		self._windowFocused = true

		if pane:IsVisible() and not pane:IsFieldFocused() then
			pane:CaptureFocus(self._lastFocusIndex)
		end
	end))

	self._maid:GiveTask(widget.WindowFocusReleased:Connect(function()
		self._windowFocused = false
	end))

	self._maid:GiveTask(widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		if self._isRestoring then
			return
		end

		if not widget.Enabled then
			pane:Hide()
			pane:Reset()
			self._targets = {}
		end
	end))

	self._maid:GiveTask(plugin.Unloading:Connect(function()
		self:Destroy()
	end))

	return self
end

function ChangeSizeWidget:Open(target: GuiObject?)
	if not self._batchHandled then
		self._batchHandled = true
		self._batchClosed = self._widget.Enabled

		self._maid._batch = task.defer(function()
			self._batchHandled = false
			self._batchClosed = false
		end)

		if self._batchClosed then
			self:Close()
			return
		end
	elseif self._batchClosed then
		return
	end

	local targets = self:_resolveTargets(target)
	if not targets then
		return
	end

	local isOpen = self._widget.Enabled
	self._targets = targets
	self._pane:SetTarget(targets[1])

	if isOpen then
		return
	end

	self:_show(1)
end

function ChangeSizeWidget:FocusField(index: number)
	if self._widget.Enabled and self._pane:IsVisible() then
		self._lastFocusIndex = index

		self:_raiseWindow()
		self._pane:CaptureFocus(index)

		return
	end

	local targets = self:_resolveTargets(nil)
	if not targets then
		return
	end

	self._targets = targets
	self._pane:SetTarget(targets[1])

	self:_show(index)
end

function ChangeSizeWidget:_resolveTargets(target: GuiObject?): { GuiObject }?
	local targets = {}

	for _, selectedInstance in Selection:Get() do
		if selectedInstance:IsA("GuiObject") then
			table.insert(targets, selectedInstance)
		end
	end

	if #targets > 0 then
		return targets
	end

	targets = table.clone(self._targets)

	if target and not table.find(targets, target) then
		table.insert(targets, target)
	end

	if #targets == 0 then
		return nil
	end

	return targets
end

function ChangeSizeWidget:_show(focusIndex: number)
	self._lastFocusIndex = focusIndex
	self._pane:Reset()

	if self._widget.Enabled then
		self:_raiseWindow()
	else
		self._widget.Enabled = true
	end

	self._pane:Show()
	self._pane:CaptureFocus(focusIndex)
end

function ChangeSizeWidget:_raiseWindow()
	local widget = self._widget

	if not widget.Enabled or self._windowFocused then
		return
	end

	self._isRestoring = true
	widget.Enabled = false
	widget.Enabled = true
	self._isRestoring = false
end

function ChangeSizeWidget:Close()
	self._pane:Hide()
	self._widget.Enabled = false
end

function ChangeSizeWidget:_apply(values)
	local resolved = {}

	for _, target in self._targets do
		if not target:IsDescendantOf(game) then
			continue
		end

		local size = target.Size
		local variables = getChangeSizeVariables(target.AbsoluteSize, size)

		local components = {
			XScale = size.X.Scale;
			XOffset = size.X.Offset;
			YScale = size.Y.Scale;
			YOffset = size.Y.Offset;
		}

		for _, key in COMPONENT_KEYS do
			local text = values[key]
			if not text or text == "" then
				continue
			end

			local value = ExpressionUtils.evaluate(text, variables)
			if not value then
				self._pane:FlagField(key)
				return
			end

			components[key] = value
		end

		table.insert(resolved, {
			Size = UDim2.new(components.XScale, components.XOffset, components.YScale, components.YOffset);
			Target = target;
		})
	end

	if #resolved == 0 then
		self:Close()
		return
	end

	local recording = ChangeHistoryService:TryBeginRecording("Change Size")
	if not recording then
		warn("[StudioMacros]: Failed to begin recording for Change Size")
	end

	for _, entry in resolved do
		entry.Target.Size = entry.Size
	end

	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end

	self:Close()
end

function ChangeSizeWidget:Destroy()
	if instance == self then
		instance = nil
	end

	self._maid:DoCleaning()
end

return ChangeSizeWidget
