local function usesEnabled(gui)
	return gui:IsA("LayerCollector") or gui:IsA("UIStroke") or gui:IsA("UIGradient")
end

return {
	Name = "Toggle Visibility";
	Description = "Toggle the object's visibility.";

	Predicate = function(gui)
		return gui ~= nil and (gui:IsA("GuiObject") or usesEnabled(gui))
	end;

	ToggleValue = function(gui)
		if not gui then
			return nil
		end

		if usesEnabled(gui) then
			return gui.Enabled
		else
			return gui.Visible
		end
	end;

	Macro = function(gui)
		if usesEnabled(gui) then
			gui.Enabled = not gui.Enabled
		else
			gui.Visible = not gui.Visible
		end
	end;
}
