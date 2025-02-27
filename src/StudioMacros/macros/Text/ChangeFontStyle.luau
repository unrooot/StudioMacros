return {
	Name = "Change Font Style";
	Description = "Change the font style, including font weight for bold and italic text.";
	CustomResults = "FontStyle";

	Predicate = function(gui)
		return gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
	end;

	Macro = function(gui, _, fontWeight, isItalic)
		if not fontWeight then
			return
		end

		local currentFontFace = gui.FontFace
		local fontStyle = isItalic and Enum.FontStyle.Italic or Enum.FontStyle.Normal

		gui.FontFace = Font.new(currentFontFace.Family, fontWeight, fontStyle)
	end;
}