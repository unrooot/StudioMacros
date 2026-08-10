local require = require(script.Parent.loader).load(script)

local Maid = require("Maid")
local Rx = require("Rx")
local cancellableDelay = require("cancellableDelay")

local CLOSE_DELAY = 0.15
local WIDGET_ID = "StudioMacros_CustomResults"

local TITLES = {
	Color = "change color";
	Font = "change font";
	FontStyle = "change font style";
}

local CustomResultsWidget = {}
CustomResultsWidget.ClassName = "CustomResultsWidget"
CustomResultsWidget.__index = CustomResultsWidget

function CustomResultsWidget.new(plugin: Plugin, palette)
	local self = setmetatable({}, CustomResultsWidget)

	self._maid = Maid.new()
	self._palette = palette

	local widget = plugin:CreateDockWidgetPluginGui(WIDGET_ID, DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		true,
		650,
		520,
		420,
		320
	))

	widget.Name = "StudioMacrosCustomResults"
	widget.Title = "studio macros"
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	widget.Enabled = false

	self._maid:GiveTask(widget)
	self._widget = widget

	self._maid:GiveTask(Rx.combineLatest({
		CustomResults = palette:ObserveCustomResults();
		IsVisible = palette:ObserveVisible();
		WidgetRequested = palette:ObserveWidgetRequested();
	}):Subscribe(function(state)
		if state.CustomResults and state.WidgetRequested and palette:IsVisible() then
			self:_open(state.CustomResults)
		elseif palette:IsVisible() then
			self:_close(0)
		else
			self:_close(CLOSE_DELAY)
		end
	end))

	self._maid:GiveTask(widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		if widget.Enabled then
			return
		end

		if self._selfClosed then
			self._selfClosed = false
			return
		end

		if palette:IsDocked() and palette:IsVisible() then
			palette:Hide()
		end
	end))

	self._maid:GiveTask(plugin.Unloading:Connect(function()
		self:Destroy()
	end))

	return self
end

function CustomResultsWidget:_open(customResults: string)
	self._maid._closeTimer = nil

	self._widget.Title = TITLES[customResults] or "studio macros"
	self._selfClosed = false
	self._widget.Enabled = true

	if self._palette:IsDocked() then
		return
	end

	self._palette:SetDockTarget(self._widget)
	self._palette:CaptureFocus()
end

function CustomResultsWidget:_close(delayTime: number)
	if not self._widget.Enabled and not self._palette:IsDocked() then
		return
	end

	self._selfClosed = true
	self._widget.Enabled = false

	local function undock()
		self._palette:SetDockTarget(nil)
	end

	if delayTime <= 0 then
		self._maid._closeTimer = nil
		undock()
		return
	end

	self._maid._closeTimer = cancellableDelay(delayTime, undock)
end

function CustomResultsWidget:Destroy()
	self._maid:DoCleaning()
end

return CustomResultsWidget
