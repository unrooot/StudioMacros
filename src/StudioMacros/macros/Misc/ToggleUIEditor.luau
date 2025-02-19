local disabled = false

return {
	Name = "Toggle UI Editor";
	Description = "Toggle the default Studio UI editor.";

	Macro = function(_, plugin)
        disabled = plugin:GetSetting("UIEditorDisabled") or false
        disabled = not disabled
        plugin:SetSetting("UIEditorDisabled", disabled)
	end;
}