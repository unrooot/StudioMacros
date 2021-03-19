-- originally by retro_mada
-- redone by friendlybiscuit to fix it not working all the time
-- ui editor will now perish alone and un-loved

local disabled = false

return {
    name = 'Toggle UI Editor',
    extended = true,
    desc = '[StudioMacros] Toggle the garbage Roblox UI Editor.',
    func = function(plugin)
        disabled = plugin:GetSetting('UIEditorDisabled') or false
        disabled = not disabled
        plugin:SetSetting('UIEditorDisabled', disabled)
        
        if _G.refresh_editor then _G.refresh_editor() end
    end
}