return {
	Name = "Toggle Visibility";
	Description = "Toggle the object's visibility.";

	Predicate = function(gui)
		return gui ~= nil and (gui:IsA("GuiObject") or gui:IsA("ScreenGui") or gui:IsA("UIStroke") or gui:IsA("UIGradient"))
	end;

	ToggleValue = function(gui)
		if not gui then
			return nil
		end

		if gui:IsA("ScreenGui") or gui:IsA("UIStroke") or gui:IsA("UIGradient") then
			return gui.Enabled
		else
			return gui.Visible
		end
	end;

	Macro = function(gui)
		if gui:IsA("ScreenGui") or gui:IsA("UIStroke") or gui:IsA("UIGradient") then
			gui.Enabled = not gui.Enabled
		else
			gui.Visible = not gui.Visible
		end
	end;
}