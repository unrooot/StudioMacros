local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

return {
	name = "customTarget";
	desc = "[StudioMacros] Tag an instance with customTarget (uses CollectionService).";
	func = function(gui)
		if not table.find(CollectionService:GetTags(gui), "customTarget") then
			CollectionService:AddTag(gui, "customTarget")

			if not gui:FindFirstChild("customTarget") then
				local customTarget = Instance.new("NumberValue")
				customTarget.Name = "customTarget"
				customTarget.Parent = gui
	
				Selection:Set({customTarget})
			end
		else
			CollectionService:RemoveTag(gui, "customTarget")
			
			local value = gui:FindFirstChild("customTarget")
			if value then
				value:Destroy()
			end
		end
	end;
}