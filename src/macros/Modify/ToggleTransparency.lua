return {
	name = "Toggle Transparency";
	desc = "[StudioMacros] Toggles the BackgroundTransparency between 0 and 1.";
	func = function(gui)
		local transparency = gui.BackgroundTransparency
		gui.BackgroundTransparency = transparency == 1 and 0 or 1
	end;
}