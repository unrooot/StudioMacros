return function(instance)
	if instance:IsA("TextBox") then
		instance:GetPropertyChangedSignal("Text"):Connect(function()
			instance.Text = instance.Text:gsub("%s+")
		end)
	end
end