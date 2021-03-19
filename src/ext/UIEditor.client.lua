local CoreGui = game:GetService('CoreGui')
local Selection = game:GetService('Selection')

local function toggle_editor()
	local enabled = plugin:GetSetting('UIEditorDisabled')

	local editor = CoreGui:FindFirstChild('RobloxGUIEditor')
	for _, h in pairs(editor:GetDescendants()) do
		if h:IsA('ScreenGui') then
			h.Enabled = enabled
		end
	end
end

local function selection_changed()
	local selected = Selection:Get()

	for _, v in pairs(selected) do
		if v:IsA('GuiObject') then
			if CoreGui:FindFirstChild('RobloxGUIEditor') then
				toggle_editor()
			end
			break
		end
	end 
end

CoreGui.ChildAdded:Connect(function(child)
	if child.Name == 'RobloxGUIEditor' then
		toggle_editor()
		local handles = child:WaitForChild('m_handles')
		handles.ChildAdded:Connect(function(child)
			if child:IsA('ScreenGui') then
				child.Enabled = plugin:GetSetting('UIEditorDisabled')
			end
		end)
	end
end)

Selection.SelectionChanged:Connect(selection_changed)