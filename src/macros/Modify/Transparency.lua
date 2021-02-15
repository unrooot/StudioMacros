return {
	name = "Transparency";
	desc = "[StudioMacros] Remove the background/border on an instance.";
	func = function(gui)
		gui.BackgroundTransparency = 1
		gui.BorderSizePixel = 0
	end;
}