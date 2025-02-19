local modules = script:WaitForChild("modules")
local loader = script.Parent:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapPlugin(modules)

local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")

local Blend = require("Blend")
local CommandGroup = require("CommandGroup")
local CommandPalette = require("CommandPalette")
local Maid = require("Maid")

local function initialize(plugin)
	local maid = Maid.new()

	local pane = maid:Add(CommandPalette.new())

	maid:GiveTask(Blend.New "ScreenGui" {
		Name = "StudioMacrosCommands";
		DisplayOrder = 1000;
		Parent = CoreGui;

		pane:Render();
	}:Subscribe())

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

	for _, group in script.macros:GetChildren() do
		if group:IsA("Folder") then
			local groupData = group:FindFirstChild("GroupData")
			if not groupData then
				continue
			end

			local groupEntry = pane:AddGroup(require(groupData))

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
					maid:GiveTask(task.spawn(function()
						local editor = CoreGui:WaitForChild("RobloxGUIEditor")

						local function refreshEditor()
							for _, descendant in editor:GetDescendants() do
								if descendant:IsA("ScreenGui") then
									descendant.Enabled = not plugin:GetSetting("UIEditorDisabled")
								end
							end
						end

						local function bind(object)
							if object:IsA("ScreenGui") then
								object.Enabled = not plugin:GetSetting("UIEditorDisabled")

								maid:GiveTask(object.Changed:Connect(function()
									object.Enabled = not plugin:GetSetting("UIEditorDisabled")
								end))
							end
						end

						maid:GiveTask(editor.DescendantAdded:Connect(bind))

						for _, descendant in editor:GetDescendants() do
							bind(descendant)
						end
					end))
				end

				local function activated()
					local selectedInstance = Selection:Get()[1]
					local newInstance = macroData.Function(selectedInstance, plugin)

					if newInstance then
						Selection:Set({ newInstance })
					end

					if macro.Name == "ToggleUIEditor" then
						local editor = CoreGui:FindFirstChild("RobloxGUIEditor")
						if editor then
							for _, descendant in editor:GetDescendants() do
								if descendant:IsA("ScreenGui") then
									descendant.Enabled = not plugin:GetSetting("UIEditorDisabled")
								end
							end
						end
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