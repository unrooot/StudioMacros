return {
	Name = "Toggle Visibility";
	Description = "Toggle the object's visibility.";

	Predicate = function(gui)
		return gui ~= nil and (gui:IsA("GuiObject") or gui:IsA("ScreenGui"))
	end;

	Macro = function(gui)
		if gui:IsA("ScreenGui") then
			gui.Enabled = not gui.Enabled
		else
			gui.Visible = not gui.Visible
		end
	end;
}