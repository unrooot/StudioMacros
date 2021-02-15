local Selection = game:GetService("Selection")
local macros = script.Parent.macros

for _,module in pairs(macros:GetDescendants()) do
	if module:IsA("ModuleScript") then
		local data = require(module)
		local macro = plugin:CreatePluginAction(data.name, data.name, data.desc, "rbxassetid://5972593639", true)

		macro.Triggered:Connect(function()
			local selected = Selection:Get()

			if #selected > 0 then
				for _,instance in ipairs(selected) do
					data.func(instance)
				end
			else
				data.func()
			end
		end)
	end
end