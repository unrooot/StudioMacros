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
local Maid = require("Maid")
local RxInstanceUtils = require("RxInstanceUtils")
local ValueObject = require("ValueObject")

local function initialize(plugin)
	local maid = Maid.new()

	local pane = maid:Add(CommandPalette.new())

	maid:GiveTask(Blend.New "ScreenGui" {
		Name = "StudioMacrosCommands";
		DisplayOrder = 1000;
		Parent = CoreGui;

		pane:Render();
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
		pane.TargetSelection.Value = Selection:Get()
		pane:Show()
	end))

	maid:GiveTask(plugin.Unloading:Connect(function()
		maid:Destroy()
	end))

	for index, group in script.macros:GetChildren() do
		if group:IsA("Folder") then
			local groupData = group:FindFirstChild("GroupData")
			if not groupData then
				continue
			end

			local groupEntry = pane:AddGroup(require(groupData))

			if index ~= 1 then
				groupEntry:SetIsCollapsed(true)
			end

			for macroIndex, macro in group:GetChildren() do
				if macro.Name == "GroupData" or not macro:IsA("ModuleScript") then
					continue
				end

				local macroData = require(macro)
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

				local function activated(leavePaneOpen: boolean?)
					if macroEntry:IsGroupHeader() then
						return
					end

					local undoRecording = ChangeHistoryService:TryBeginRecording(macroData.Name)
					if not undoRecording then
						warn("[StudioMacros]: Failed to begin recording for", macroData.Name)
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

					if macro.Name == "ToggleUIEditor" then
						uiEditorVisible.Value = not uiEditorVisible.Value
						return
					end

					for _, selectedInstance in selectedInstances do
						if macroData.Predicate then
							local validInstance = macroData.Predicate(selectedInstance)
							if not validInstance then
								print(macroData.Name, "failed predicate", selectedInstance)
								continue
							end
						end

						local newInstance = macroData.Macro(selectedInstance, plugin)

						if not leavePaneOpen then
							pane:Hide()
						end

						if newInstance then
							table.insert(newSelection, newInstance)
						end
					end

					if #newSelection > 0 then
						Selection:Set(newSelection)
					elseif revertSelection then
						Selection:Set(selectedInstances)
					end

					ChangeHistoryService:FinishRecording(undoRecording, Enum.FinishRecordingOperation.Commit)
				end

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