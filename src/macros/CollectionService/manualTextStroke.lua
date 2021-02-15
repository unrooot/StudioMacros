local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

return {
	name = "manualTextStroke";
	desc = "[StudioMacros] Tag an instance with manualTextStroke (uses CollectionService).";
	func = function(gui)
		if not table.find(CollectionService:GetTags(gui), "manualTextStroke") then
			CollectionService:AddTag(gui, "manualTextStroke")

			if not gui:FindFirstChild("TextStroke") then
				local TextStroke = Instance.new("NumberValue")
				TextStroke.Name = "TextStroke"
				TextStroke.Parent = gui
	
				Selection:Set({TextStroke})
			end
		else
			CollectionService:RemoveTag(gui, "manualTextStroke")
			
			local value = gui:FindFirstChild("TextStroke")
			if value then
				value:Destroy()
			end
		end
	end;
}