return {
	Name = "Toggle Color";
	Description = "Toggle the object's color between black and white.";

	Predicate = function(gui)
		return gui:IsA("Frame")
			or gui:IsA("TextLabel")
			or gui:IsA("TextButton")
			or gui:IsA("TextBox")
			or gui:IsA("UIStroke")
	end;

	Macro = function(gui)
		if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
			gui.TextColor3 = gui.TextColor3 == Color3.new(1, 1, 1) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		elseif gui:IsA("UIStroke") then
			gui.Color = gui.Color == Color3.new(1, 1, 1) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		else
			gui.BackgroundColor3 = gui.BackgroundColor3 == Color3.new(1, 1, 1) and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		end
	end;
}