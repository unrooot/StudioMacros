local Selection = game:GetService("Selection")

local macros = script.Parent.macros

for _, module in pairs(macros:GetDescendants()) do
	if module:IsA("ModuleScript") then
		local data = require(module)
		local macro = plugin:CreatePluginAction(data.name, data.name, data.desc, "rbxassetid://5972593639", true)

        if data.init then
            spawn(function() data.init(plugin) end)
        end

		macro.Triggered:Connect(function()
			local selected = Selection:Get()

			if #selected > 0 then
				for _, instance in ipairs(selected) do
					if data.extended then
						data.func(plugin, instance)
					else
						data.func(instance)
					end
				end
			else
                if data.extended then
				    data.func(data.extended and plugin)
                end
			end
		end)
	end
end