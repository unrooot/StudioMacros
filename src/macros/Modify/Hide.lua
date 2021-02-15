local function hide(instance)
	if instance:IsA("TextLabel") or instance:IsA("TextBox") then
		instance.TextTransparency = 1
		instance.TextStrokeTransparency = 1
	elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") or instance:IsA("ViewportFrame") then
		instance.ImageTransparency = 1
	elseif instance:IsA("ScrollingFrame") then
		instance.ScrollBarImageTransparency = 1
	elseif instance:IsA("Frame") then
		instance.BackgroundTransparency = 1
	end
end

return {
	name = "Hide UI";
	desc = "[StudioMacros] Hide the UI of a selected ScreenGui.";
	func = function(gui)
		if not gui.ClassName == "ScreenGui" then
			gui = gui:FindFirstAncestorOfClass("ScreenGui")
		end

		for _,instance in pairs(gui:GetDescendants()) do
			if instance:IsA("ImageButton") or instance:IsA("ScrollingFrame") or instance:IsA("TextBox") or instance:IsA("TextButton") then
				instance.Visible = false
			end
		
			hide(instance)
		end
	end;
}