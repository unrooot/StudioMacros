local require = require(script.Parent.loader).load(script)

local Selection = game:GetService("Selection")

local SelectionUtils = require("SelectionUtils")

local SimilarSelection = {}
SimilarSelection.ClassName = "SimilarSelection"
SimilarSelection.__index = SimilarSelection

function SimilarSelection.new(excludeAnchors: boolean?)
	local self = setmetatable({}, SimilarSelection)

	self._excludeAnchors = excludeAnchors
	self._state = nil
	self._toastValue = nil
	self._batchActive = false

	return self
end

function SimilarSelection:_beginBatch(): boolean
	if self._batchActive then
		return false
	end

	self._batchActive = true
	task.defer(function()
		self._batchActive = false
	end)

	return true
end

function SimilarSelection:_isContinuation(selection: { Instance }): boolean
	local state = self._state
	if not state or #selection ~= #state.Selected then
		return false
	end

	for _, instance in selection do
		if not state.SelectedSet[instance] then
			return false
		end
	end

	return true
end

function SimilarSelection:GetToastValue(): string?
	return self._toastValue
end

function SimilarSelection:Run(instance: Instance): { Instance }?
	if not self:_beginBatch() then
		return nil
	end

	local selection = Selection:Get()
	if #selection == 0 then
		selection = { instance }
	end

	local state = self._state
	local continuing = self:_isContinuation(selection)
	local anchors, anchorSet, signatures, startLevel, previousCount

	if continuing then
		anchors = state.Anchors
		anchorSet = state.AnchorSet
		signatures = state.Signatures
		startLevel = state.Level + 1
		previousCount = #state.Matches
	else
		anchors = selection
		anchorSet = {}
		signatures = {}

		for _, anchor in anchors do
			anchorSet[anchor] = true
			signatures[SelectionUtils.getSignature(anchor)] = true
		end

		startLevel = 1
		previousCount = #anchors
	end

	local chain = SelectionUtils.getScopeChain(anchors[1])
	local level, matches = SelectionUtils.findNextScope(chain, signatures, startLevel, previousCount)

	if not level then
		if continuing then
			self._toastValue = `{#state.Selected} in {state.ScopeName} (max)`
			return state.Selected
		end

		self._state = nil
		self._toastValue = "no matches"

		return nil
	end

	local selected = matches

	if self._excludeAnchors then
		selected = {}

		for _, match in matches do
			if not anchorSet[match] then
				table.insert(selected, match)
			end
		end
	end

	local selectedSet = {}
	for _, match in selected do
		selectedSet[match] = true
	end

	local scope = chain[level]

	self._state = {
		Anchors = anchors;
		AnchorSet = anchorSet;
		Signatures = signatures;
		Level = level;
		Matches = matches;
		Selected = selected;
		SelectedSet = selectedSet;
		ScopeName = scope.Name;
	}

	self._toastValue = `{#selected} in {scope.Name}`

	return selected
end

return SimilarSelection
