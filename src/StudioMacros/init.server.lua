-- yo
local modules = script:WaitForChild("modules")
local loader = script.Parent:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapPlugin(modules)

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")

local Blend = require("Blend")
local CommandGroup = require("CommandGroup")
local CommandPalette = require("CommandPalette")
local MacroToast = require("MacroToast")
local Maid = require("Maid")
local RxInstanceUtils = require("RxInstanceUtils")
local ValueObject = require("ValueObject")

local function getToggleValue(macroData, instance)
	if not string.find(macroData.Name, "Toggle", 1, true) then
		return nil
	end

	if macroData.ToggleValue then
		return macroData.ToggleValue(instance)
	end

	if not instance then
		return nil
	end

	local property = string.match(macroData.Name, "^Toggle%s+(%S+)$")
	if not property then
		return nil
	end

	local success, value = pcall(function()
		return instance[property]
	end)

	if not success then
		return nil
	end

	return value
end

local function getToastValue(macroData, instance)
	if macroData.ToastValue then
		return macroData.ToastValue(instance)
	end

	return getToggleValue(macroData, instance)
end

local function getToastName(macroData, instance)
	if macroData.ToastName then
		local name = macroData.ToastName(instance)
		if name then
			return name
		end
	end

	return macroData.Name
end

local function appendSelection(newSelection, result)
	if type(result) == "table" then
		for _, instance in result do
			table.insert(newSelection, instance)
		end
	elseif result then
		table.insert(newSelection, result)
	end
end

local function initialize(plugin)
	local maid = Maid.new()

	local pane = maid:Add(CommandPalette.new())
	local toast = maid:Add(MacroToast.new())

	maid:GiveTask(Blend.New "ScreenGui" {
		Name = "StudioMacrosCommands";
		DisplayOrder = 1000;
		Parent = CoreGui;

		pane:Render();
		toast:Render();
	}:Subscribe())

	local uiEditorVisible = maid:Add(ValueObject.new(plugin:GetSetting("UIEditorDisabled") or true))

	local toggleCommand = plugin:CreatePluginAction(
		"StudioMacros Commands",
		"StudioMacros Commands",
		"Toggle the StudioMacros command palette",
		"rbxassetid://5972593639",
		true
	)

	maid:GiveTask(toggleCommand.Triggered:Connect(function()
		if pane:IsVisible() then
			pane:CaptureFocus()
		end

		pane.TargetSelection.Value = Selection:Get()
		pane:Show()
	end))

	maid:GiveTask(plugin.Unloading:Connect(function()
		maid:Destroy()
	end))

	-- Tracks the last macro run so "Repeat Last Macro" can replay it. This is
	-- shared across every group/macro, so it lives above the group loop.
	local lastActivated: ((boolean?, ...any) -> ())? = nil
	local lastArguments: { any }? = nil

	for index, group in script.macros:GetChildren() do
		if group:IsA("Folder") then
			local groupDataModule = group:FindFirstChild("GroupData")
			if not groupDataModule then
				continue
			end

			local groupData = require(groupDataModule)
			local groupEntry = pane:AddGroup(groupData)
			groupEntry.LayoutOrder.Value = index

			if index ~= 1 then
				groupEntry:SetIsCollapsed(true)
			end

			local activeMacro, leaveActiveMacroOpen
			maid:GiveTask(pane.CustomResultsReset:Connect(function()
				activeMacro = nil
			end))

			for macroIndex, macro in group:GetChildren() do
				if macro.Name == "GroupData" or not macro:IsA("ModuleScript") then
					continue
				end

				local macroData = require(macro)

				if type(macroData) == "function" then
					macroData = macroData(require)
				end

				if macroData.Initialize then
					macroData.Initialize(plugin)
				end

				local pluginAction = plugin:CreatePluginAction(
					macroData.Name,
					macroData.Name,
					"[StudioMacros]: " .. macroData.Description,
					"rbxassetid://5972593639",
					true
				)

				local macroEntry = groupEntry:AddEntry(macroData)
				macroEntry:SetDefaultIndex(macroIndex)

				if macro.Name == "ToggleUIEditor" then
					maid:GiveTask(RxInstanceUtils.observeLastNamedChildBrio(CoreGui, "Folder", "RobloxGUIEditor")
						:Subscribe(function(editorBrio)
							if editorBrio:IsDead() then
								return
							end

							local editor = editorBrio:GetValue()

							editorBrio:ToMaid():GiveTask(RxInstanceUtils.observeDescendantsOfClassBrio(editor, "ScreenGui")
								:Subscribe(function(screenGuiBrio)
									if screenGuiBrio:IsDead() then
										return
									end

									local screenGui = screenGuiBrio:GetValue()

									screenGuiBrio:ToMaid():GiveTask(uiEditorVisible:Observe():Subscribe(function(isVisible)
										task.defer(function()
											screenGui.Enabled = isVisible
										end)
									end))
								end))
						end))

					maid:GiveTask(RxInstanceUtils.observeLastNamedChildBrio(CoreGui, "ScreenGui", "RobloxGui")
						:Subscribe(function(screenGuiBrio)
							if screenGuiBrio:IsDead() then
								return
							end

							local screenGui = screenGuiBrio:GetValue()

							screenGuiBrio:ToMaid():GiveTask(uiEditorVisible:Observe():Subscribe(function(isVisible)
								screenGui.Enabled = isVisible
							end))
						end))
				end

				local function activated(leavePaneOpen: boolean?, ...)
					if macroEntry:IsGroupHeader() then
						return
					end

					if macro.Name == "RepeatLastMacro" then
						if lastActivated and lastArguments then
							lastActivated(leavePaneOpen, table.unpack(lastArguments, 1, lastArguments.n))
						elseif not leavePaneOpen then
							pane:Hide()
						end
						return
					end

					if macro.Name == "ToggleUIEditor" then
						uiEditorVisible.Value = not uiEditorVisible.Value
						toast:ShowMacro(macroData.Name, groupData.Icon, uiEditorVisible.Value)
						if not leavePaneOpen then
							pane:Hide()
						end
						return
					end

					local customResults = macroData.CustomResults
					local arguments = {...}
					if customResults and #arguments == 0 then
						if not pane:IsVisible() then
							pane.TargetSelection.Value = Selection:Get()
							pane:Show()
						end

						pane.TargetProperty.Value = macroData.TargetProperty
						pane:SetCustomResults(customResults)
						activeMacro = macroData

						if leavePaneOpen then
							leaveActiveMacroOpen = true
						end

						return
					end

					if not leavePaneOpen then
						activeMacro = nil
					end

					local newSelection = {}
					local selectedInstances = Selection:Get()

					-- HACK: This is necessary because if you click a
					-- TextButton in the palette, your selection will be
					-- cleared, which is not desired. idk if this will lead to
					-- more unintended behavior yet, also if you collapse a
					-- group it will clear your selection before a macro is
					-- selected.
					local revertSelection = false
					if (not selectedInstances or #selectedInstances == 0) and pane.TargetSelection.Value then
						selectedInstances = pane.TargetSelection.Value
						revertSelection = true
					end

					local undoRecording
					local toggledInstance
					local packedArguments = table.pack(...)

					lastActivated = activated
					lastArguments = packedArguments

					local function startRecording()
						undoRecording = ChangeHistoryService:TryBeginRecording(macroData.Name)
						if not undoRecording then
							warn("[StudioMacros]: Failed to begin recording for", macroData.Name)
						end
					end

					local success, macroError = xpcall(function()
						if #selectedInstances > 0 then
							startRecording()
							for _, selectedInstance in selectedInstances do
								if macroData.Predicate then
									local validInstance = macroData.Predicate(selectedInstance)
									if not validInstance then
										print(macroData.Name, "failed predicate", selectedInstance)
										continue
									end
								end

								local newInstance = macroData.Macro(selectedInstance, plugin, table.unpack(packedArguments, 1, packedArguments.n))
								toggledInstance = selectedInstance

								if not leavePaneOpen then
									if leaveActiveMacroOpen then
										pane:SetCustomResults(nil)
									else
										pane:Hide()
									end
								end

								appendSelection(newSelection, newInstance)
							end
						else
							if not macroData.Predicate then
								startRecording()
								local newInstance = macroData.Macro(nil, plugin, table.unpack(packedArguments, 1, packedArguments.n))

								if not leavePaneOpen then
									if leaveActiveMacroOpen then
										pane:SetCustomResults(nil)
									else
										pane:Hide()
									end
								end

								appendSelection(newSelection, newInstance)
							end
						end

						leaveActiveMacroOpen = nil

						if #newSelection > 0 then
							Selection:Set(newSelection)
							pane.TargetSelection.Value = newSelection
						elseif revertSelection then
							Selection:Set(selectedInstances)
							pane.TargetSelection.Value = selectedInstances
						end
					end, debug.traceback)

					if undoRecording then
						local operation = Enum.FinishRecordingOperation.Cancel
						if success then
							operation = Enum.FinishRecordingOperation.Commit
						end
						ChangeHistoryService:FinishRecording(undoRecording, operation)
					end

					if success then
						toast:ShowMacro(
							getToastName(macroData, toggledInstance),
							groupData.Icon,
							getToastValue(macroData, toggledInstance)
						)
					end

					if not success then
						error(macroError, 0)
					end
				end

				maid:GiveTask(pane.CustomResultActivated:Connect(function(customResult, ...)
					if activeMacro ~= macroData then
						return
					end

					if customResult == macroData.CustomResults then
						activated(...)
					end
				end))

				maid:GiveTask(macroEntry.Activated:Connect(activated))
				maid:GiveTask(pluginAction.Triggered:Connect(activated))
			end
		end
	end

	return maid
end

if plugin then
	initialize(plugin)
end
