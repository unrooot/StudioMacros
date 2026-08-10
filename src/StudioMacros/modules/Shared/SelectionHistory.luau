local require = require(script.Parent.loader).load(script)

local Selection = game:GetService("Selection")

local Maid = require("Maid")

local MAX_ENTRIES = 50

local SelectionHistory = {}
SelectionHistory.ClassName = "SelectionHistory"
SelectionHistory.__index = SelectionHistory

local instance = nil

function SelectionHistory.get(plugin: Plugin)
	if not instance then
		instance = SelectionHistory.new(plugin)
	end

	return instance
end

function SelectionHistory.new(plugin: Plugin)
	local self = setmetatable({}, SelectionHistory)

	self._maid = Maid.new()
	self._entries = {}
	self._index = 0
	self._toastValue = nil
	self._batchActive = false

	self:_record(Selection:Get())

	self._maid:GiveTask(Selection.SelectionChanged:Connect(function()
		self:_record(Selection:Get())
	end))

	self._maid:GiveTask(plugin.Unloading:Connect(function()
		self:Destroy()
	end))

	return self
end

local function isSameSelection(a: { Instance }?, b: { Instance }?): boolean
	if not a or not b or #a ~= #b then
		return false
	end

	for _, selectedInstance in a do
		if not table.find(b, selectedInstance) then
			return false
		end
	end

	return true
end

function SelectionHistory:_beginBatch(): boolean
	if self._batchActive then
		return false
	end

	self._batchActive = true
	task.defer(function()
		self._batchActive = false
	end)

	return true
end

function SelectionHistory:_record(selection: { Instance })
	if #selection == 0 then
		return
	end

	if isSameSelection(selection, self._entries[self._index]) then
		return
	end

	for index = #self._entries, self._index + 1, -1 do
		table.remove(self._entries, index)
	end

	table.insert(self._entries, table.clone(selection))

	if #self._entries > MAX_ENTRIES then
		table.remove(self._entries, 1)
	end

	self._index = #self._entries
end

local function getLiveInstances(entry: { Instance }): { Instance }
	local live = {}

	for _, selectedInstance in entry do
		if selectedInstance:IsDescendantOf(game) then
			table.insert(live, selectedInstance)
		end
	end

	return live
end

function SelectionHistory:_navigate(step: number): { Instance }?
	if not self:_beginBatch() then
		return nil
	end

	while true do
		local nextIndex = self._index + step
		local entry = self._entries[nextIndex]

		if not entry then
			self._toastValue = if step < 0 then "oldest" else "newest"
			return nil
		end

		local live = getLiveInstances(entry)

		if #live == 0 then
			table.remove(self._entries, nextIndex)

			if nextIndex < self._index then
				self._index -= 1
			end

			continue
		end

		self._entries[nextIndex] = live
		self._index = nextIndex

		local label = if #live == 1 then live[1].Name else `{#live} instances`
		self._toastValue = `{label} ({self._index}/{#self._entries})`

		return live
	end
end

function SelectionHistory:GetToastValue(): string?
	return self._toastValue
end

function SelectionHistory:Back(): { Instance }?
	return self:_navigate(-1)
end

function SelectionHistory:Forward(): { Instance }?
	return self:_navigate(1)
end

function SelectionHistory:Destroy()
	if instance == self then
		instance = nil
	end

	self._maid:DoCleaning()
end

return SelectionHistory
