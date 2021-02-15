local CollectionService = game:GetService("CollectionService")

return {
	name = "noFade";
	desc = "[StudioMacros] Tag an instance with noFade (uses CollectionService).";
	func = function(gui)
		if not table.find(CollectionService:GetTags(gui), "noFade") then
			CollectionService:AddTag(gui, "noFade")
		else
			CollectionService:RemoveTag(gui, "noFade")
		end
	end;
}