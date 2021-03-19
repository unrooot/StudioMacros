-- retro_mada

local CoreGui = game:GetService('CoreGui')

local function toggle_editor(enabled)
	local editor = CoreGui:FindFirstChild('RobloxGUIEditor')
	for _, h in pairs(editor:GetDescendants()) do
		if h:IsA('ScreenGui') then
			h.Enabled = enabled
		end
	end
end

return {
	name = "Toggle UI Editor",
	extended = true,
	desc = "[StudioMacros] Toggle Roblox UI Editor.",
	func = function(plugin)
		local state = plugin:GetSetting('UIEditorDisabled') or false
		state = not state
		plugin:SetSetting('UIEditorDisabled', state)
		toggle_editor(state)
	end;
}