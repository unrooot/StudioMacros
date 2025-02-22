local modules = script:WaitForChild("modules")
local loader = script.Parent:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapPlugin(modules)

local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")

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

			for _, macro in group:GetChildren() do
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

				local function activated()
					if macroEntry:IsGroupHeader() then
						return
					end

					local selectedInstance = Selection:Get()[1]
					if macroData.Predicate then
						local validInstance = macroData.Predicate(selectedInstance)
						if not validInstance then
							print(macroData.Name, "failed predicate", selectedInstance)
							return
						else
							print("passed predicate", selectedInstance)
						end
					end

					local newInstance = macroData.Macro(selectedInstance, plugin)

					if macro.Name == "ToggleUIEditor" then
						uiEditorVisible.Value = not uiEditorVisible.Value
					end

					pane:Hide()

					if newInstance then
						Selection:Set({ newInstance })
					end
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