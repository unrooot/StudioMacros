-- originally by retro_mada
-- redone by friendlybiscuit to fix it not working all the time
-- ui editor will now perish alone and un-loved

--= Constants & Variables =--
local core_gui  = game:GetService('CoreGui')
local editor    = nil

--= Wait For Editor =--
while not core_gui:FindFirstChild('RobloxGUIEditor') do wait() end
editor = core_gui.RobloxGUIEditor

--= Functions =--
function _G.refresh_editor() -- forgive me, for i regret nothing
    if not editor then return end
    
    for _, descendant in pairs(editor:GetDescendants()) do
        if descendant:IsA('ScreenGui') then
            descendant.Enabled = not plugin:GetSetting('UIEditorDisabled')
        end
    end
end

function bind(object)
    if object:IsA('ScreenGui') then
        object.Enabled = not plugin:GetSetting('UIEditorDisabled')
        
        object.Changed:Connect(function()
            object.Enabled = not plugin:GetSetting('UIEditorDisabled')
        end)
    end
end

function init()
    editor.DescendantAdded:Connect(bind)
    
    for _, descendant in pairs(editor:GetDescendants()) do
        bind(descendant)
    end
    
    _G.refresh_editor()
end

--= Init =--
init()