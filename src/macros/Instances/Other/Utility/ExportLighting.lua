local HttpService = game:GetService("HttpService")

return {
	name = "Export Lighting";
	desc = "[StudioMacros] Exports a table of data with current lighting settings.";
	func = function()
        local lighting = game.Lighting

        local lightingData = {
            Ambient = lighting.Ambient,
            Brightness = lighting.Brightness,
            ColorShift_Bottom = lighting.ColorShift_Bottom,
            ColorShift_Top = lighting.ColorShift_Top,
            GlobalShadows = lighting.GlobalShadows,
            ClockTime = lighting.ClockTime
        }

        print(HttpService:JSONEncode(lightingData))
	end;
}