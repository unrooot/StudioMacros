local require = require(script.Parent.loader).load(script)

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local Maid = require("Maid")
local NumberInputPane = require("NumberInputPane")
local evaluateNumberInput = require("evaluateNumberInput")
local formatNumber = require("formatNumber")

--[=[
	A floating window holding a single number field, shared by any macro that
	needs one value typed at it. Everything macro-specific lives in the config
	table passed to [NumberInputWidget.get]:

	```lua
	{
		Id = "AspectRatio"; -- unique; one window is kept alive per id
		Title = "aspect ratio";
		Caption = "ratio";

		Width = 300; -- optional
		Height = 120; -- optional
		RecordingName = "Change Aspect Ratio"; -- optional, defaults to Title

		Predicate = function(instance) -> boolean;

		-- optional, drives the placeholder and re-previews on change
		ObserveValue = function(target) -> Observable<number?>;

		-- optional names usable inside the typed expression
		GetVariables = function(target) -> { [string]: number };

		-- optional rewrite applied before the expression is parsed
		Sanitize = function(text) -> string;

		-- optional, reject otherwise-valid numbers
		Validate = function(value) -> boolean;

		Apply = function(target, value);
	}
	```

	@class NumberInputWidget
]=]
local NumberInputWidget = {}
NumberInputWidget.ClassName = "NumberInputWidget"
NumberInputWidget.__index = NumberInputWidget

local instances = {}

function NumberInputWidget.get(plugin: Plugin, config)
	local existing = instances[config.Id]
	if not existing then
		existing = NumberInputWidget.new(plugin, config)
		instances[config.Id] = existing
	end

	return existing
end

function NumberInputWidget.new(plugin: Plugin, config)
	local self = setmetatable({}, NumberInputWidget)

	self._config = config
	self._maid = Maid.new()
	self._plugin = plugin
	self._targets = {}
	self._windowFocused = false

	local width = config.Width or 300
	local height = config.Height or 120

	local widget = plugin:CreateDockWidgetPluginGui(`StudioMacros_{config.Id}`, DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		true,
		width,
		height,
		220,
		104
	))

	widget.Name = `StudioMacros{config.Id}`
	widget.Title = config.Title
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	widget.Enabled = false

	self._maid:GiveTask(widget)
	self._widget = widget

	local pane = self._maid:Add(NumberInputPane.new())
	pane:SetCaption(config.Caption or "")
	self._pane = pane

	self._maid:GiveTask(pane:Render({ Parent = widget }):Subscribe())

	self._maid:GiveTask(pane.Submitted:Connect(function(text)
		self:_apply(text)
	end))

	self._maid:GiveTask(pane.Cancelled:Connect(function()
		self:Close()
	end))

	self._maid:GiveTask(widget.WindowFocused:Connect(function()
		self._windowFocused = true

		if pane:IsVisible() and not pane:IsFieldFocused() then
			pane:CaptureFocus()
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
			self:_setTarget(nil)
			self._targets = {}
		end
	end))

	self._maid:GiveTask(plugin.Unloading:Connect(function()
		self:Destroy()
	end))

	return self
end

function NumberInputWidget:Open(target: Instance?)
	-- The runner fires the macro once per selected instance, so a single
	-- invocation lands here N times; only the first should decide whether this
	-- is an open or a toggle-closed.
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
	self:_setTarget(targets[1])

	if isOpen then
		return
	end

	self:_show()
end

function NumberInputWidget:Close()
	self._pane:Hide()
	self._widget.Enabled = false
end

function NumberInputWidget:_resolveTargets(target: Instance?): { Instance }?
	local targets = {}

	for _, selectedInstance in Selection:Get() do
		if self._config.Predicate(selectedInstance) then
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

function NumberInputWidget:_setTarget(target: Instance?)
	local config = self._config

	self._maid._target = nil
	self._pane:SetPlaceholder("")

	if not target then
		self._pane:SetEvaluator(nil)
		return
	end

	local function refreshEvaluator()
		self._pane:SetEvaluator(function(text)
			return self:_evaluate(text, target)
		end)
	end

	refreshEvaluator()

	if not config.ObserveValue then
		return
	end

	local maid = Maid.new()
	self._maid._target = maid

	maid:GiveTask(config.ObserveValue(target):Subscribe(function(value)
		self._pane:SetPlaceholder(value and formatNumber(value) or "")
		refreshEvaluator()
	end))
end

function NumberInputWidget:_evaluate(text: string, target: Instance): number?
	return evaluateNumberInput(self._config, text, target)
end

function NumberInputWidget:_show()
	self._pane:Reset()

	if self._widget.Enabled then
		self:_raiseWindow()
	else
		self._widget.Enabled = true
	end

	self._pane:Show()
	self._pane:CaptureFocus()
end

function NumberInputWidget:_raiseWindow()
	local widget = self._widget

	if not widget.Enabled or self._windowFocused then
		return
	end

	self._isRestoring = true
	widget.Enabled = false
	widget.Enabled = true
	self._isRestoring = false
end

function NumberInputWidget:_apply(text: string)
	if text == "" then
		self:Close()
		return
	end

	local resolved = {}

	for _, target in self._targets do
		if not target:IsDescendantOf(game) then
			continue
		end

		local value = self:_evaluate(text, target)
		if not value then
			self._pane:FlagField()
			return
		end

		table.insert(resolved, { Target = target; Value = value })
	end

	if #resolved == 0 then
		self:Close()
		return
	end

	local recordingName = self._config.RecordingName or self._config.Title
	local recording = ChangeHistoryService:TryBeginRecording(recordingName)
	if not recording then
		warn("[StudioMacros]: Failed to begin recording for", recordingName)
	end

	for _, entry in resolved do
		self._config.Apply(entry.Target, entry.Value)
	end

	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end

	self:Close()
end

function NumberInputWidget:Destroy()
	if instances[self._config.Id] == self then
		instances[self._config.Id] = nil
	end

	self._maid:DoCleaning()
end

return NumberInputWidget
