local Selection = game:GetService("Selection")

return {
	name = "Insert Configuration";
	desc = "[StudioMacros] ";
	func = function(gui)
		local configuration = Instance.new("Configuration")
		configuration.Parent = gui

		Selection:Set({configuration})
	end;
}