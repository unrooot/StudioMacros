local require = require(script.Parent.loader).load(script)

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local ChangeSizePane = require("ChangeSizePane")
local ExpressionUtils = require("ExpressionUtils")
local Maid = require("Maid")
local cancellableDelay = require("cancellableDelay")
local getChangeSizeVariables = require("getChangeSizeVariables")

local CLOSE_DELAY = 0.15
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
	self._plugin = plugin
	self._targets = {}

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
			`[StudioMacros]: Focus the {fieldName} input in the change size window (bind this to Ctrl+{index}).`,
			"rbxassetid://5972593639",
			true
		)

		self._maid:GiveTask(action.Triggered:Connect(function()
			print(`[ChangeSize] action fired: {fieldName} enabled={widget.Enabled}`)

			if not widget.Enabled then
				return
			end

			pane:CaptureFocus(index)
		end))
	end

	self._maid:GiveTask(widget:GetPropertyChangedSignal("Enabled"):Connect(function()
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
	print(`[ChangeSize] Open: enabled={self._widget.Enabled} batchHandled={self._batchHandled} batchClosed={self._batchClosed} target={target and target.Name}`)

	if not self._batchHandled then
		self._batchHandled = true
		self._batchClosed = self._widget.Enabled

		self._maid._batch = task.defer(function()
			print("[ChangeSize] batch reset")
			self._batchHandled = false
			self._batchClosed = false
		end)

		if self._batchClosed then
			print("[ChangeSize] toggling closed")
			self:Close()
			return
		end
	elseif self._batchClosed then
		return
	end

	local targets = {}

	for _, selectedInstance in Selection:Get() do
		if selectedInstance:IsA("GuiObject") then
			table.insert(targets, selectedInstance)
		end
	end

	if #targets == 0 then
		if not target then
			return
		end

		targets = table.clone(self._targets)

		if not table.find(targets, target) then
			table.insert(targets, target)
		end
	end

	local isOpen = self._widget.Enabled
	self._targets = targets
	self._pane:SetTarget(targets[1])

	if isOpen then
		return
	end

	self._maid._closeTimer = nil
	self._pane:Reset()
	self._widget.Enabled = true
	self._pane:Show()
	self._pane:CaptureFocus(1)
end

function ChangeSizeWidget:Close()
	self._pane:Hide()

	self._maid._closeTimer = cancellableDelay(CLOSE_DELAY, function()
		self._widget.Enabled = false
	end)
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
