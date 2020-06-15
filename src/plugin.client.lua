-- Pog Macros
-- { Unroot owes us each a ton of money for this! }
-- retro_mada & passhley
-- plugin stuff

-- services
local uis = game:GetService("UserInputService")

-- plugin creation & initialization
local toolbar = plugin:CreateToolbar("PogSuite")
local button = toolbar:CreateButton("PogMacros", "UI Development Macros (Industry Grade!)", "rbxassetid://5168428496")

-- services
local shortcuts = require(script.Parent.shortcuts)

-- populate information
for i, v in pairs(shortcuts) do
    local macro = plugin:CreatePluginAction(i, i, "generic", "rbxassetid://5168428496", true)
    macro.Triggered:Connect(function()
        local sel = game.Selection:Get()[1]
        v(sel)
    end)
end