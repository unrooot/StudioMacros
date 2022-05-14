return {
	name = "Decrease Text Size";
	desc = "[StudioMacros] Decrease Text Size by 1.";
	func = function(gui)
		if gui:IsA("TextLabel") or gui:IsA("TextBox") then
			gui.TextSize -= 1
		end
	end;
}