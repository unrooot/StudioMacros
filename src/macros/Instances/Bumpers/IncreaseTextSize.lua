return {
	name = "Increase Text Size";
	desc = "[StudioMacros] Increases Text Size by 1.";
	func = function(gui)
		if gui:IsA("TextLabel") or gui:IsA("TextBox") then
			gui.TextSize += 1
		end
	end;
}