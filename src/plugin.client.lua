-- Pog Macros
-- { Unroot owes us each a ton of money for this! }
-- retro_mada & passhley
-- plugin stuff

local toolbar = plugin:CreateToolbar("PogSuite")
local button = toolbar:CreateButton("PogMacros", "UI Development Macros (Industry Grade!)", "rbxassetid://5168428496")

-- widget stuff
local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, true, true, 160, 145, 160, 145)
local widget =  plugin:CreateDockWidgetPluginGui("PogMacros", widgetInfo)
widget.Title = "Pog Macros"

-- button binds
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	button:SetActive(widget.Enabled)
end)