local CollectionService = game:GetService("CollectionService")

local function show(instance, data)
	if instance:IsA("TextLabel") or instance:IsA("TextBox") then
		instance.TextTransparency = data.target
		instance.TextStrokeTransparency = data.customStroke or 1
	elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") or instance:IsA("ViewportFrame") then
		instance.ImageTransparency = data.target
	elseif instance:IsA("ScrollingFrame") then
		instance.ScrollBarImageTransparency = data.target
	elseif instance:IsA("Frame") then
		instance.BackgroundTransparency = data.target
	end
end

return {
	name = "Show UI";
	desc = "[StudioMacros] Show the UI of a selected ScreenGui.";
	func = function(gui)
		if not gui.ClassName == "ScreenGui" then
			gui = gui:FindFirstAncestorOfClass("ScreenGui")
		end

		for _,instance in pairs(gui:GetDescendants()) do
			local tags = CollectionService:GetTags(instance)
			local data = {
				noFade = false;
				customStroke = false;
				target = 0;
			}

			for _,tag in ipairs(tags) do
				if tag == "noFade" then
					data.noFade = true
				elseif tag == "customTarget" then
					local customTarget = instance:FindFirstChild("customTarget")
					assert(customTarget, "[StudioMacros] [Show] Instance is tagged with customTarget but doesn't contain customTarget value @ " .. gui:GetFullName())
					data.target = customTarget.Value
				elseif tag == "manualTextStroke" then
					local stroke = instance:FindFirstChild("TextStroke")
					assert(stroke, "[StudioMacros] [Show] Instance is tagged with manualTextStroke but doesn't contain TextStroke value @ " .. gui:GetFullName())
					data.customStroke = stroke.Value
				end
			end

			if instance:IsA("ImageButton") or instance:IsA("ScrollingFrame") or instance:IsA("TextBox") or instance:IsA("TextButton") then
				instance.Visible = true
			end
		
			if not data.noFade then
				show(instance, data)
			end
		end
	end;
}