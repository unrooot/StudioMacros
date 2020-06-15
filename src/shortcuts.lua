-- PogMacros shortcuts file

local u2 = UDim2.new
local v2 = Vector2.new
local clamp = math.clamp
local c3 = Color3.fromRGB

local shortcuts = {
	-- positioning
	["Left"] = function(gui)
		gui.AnchorPoint = v2(clamp(gui.AnchorPoint.X - 0.5, 0, 1), gui.AnchorPoint.Y)
		gui.Position = u2(clamp(gui.Position.X.Scale - 0.5, 0, 1), 0, gui.Position.Y.Scale, 0)

		return gui
	end;

	["Right"] = function(gui)
		gui.AnchorPoint = v2(clamp(gui.AnchorPoint.X + 0.5, 0, 1), gui.AnchorPoint.Y)
		gui.Position = u2(clamp(gui.Position.X.Scale + 0.5, 0, 1), 0, gui.Position.Y.Scale, 0)

		return gui
	end;

	["Up"] = function(gui)
		gui.AnchorPoint = v2(gui.AnchorPoint.X, clamp(gui.AnchorPoint.Y - 0.5, 0, 1))
		gui.Position = u2(gui.Position.X.Scale, 0, clamp(gui.Position.Y.Scale - 0.5, 0, 1), 0)

		return gui
	end;

	["Down"] = function(gui)
		gui.AnchorPoint = v2(gui.AnchorPoint.X, clamp(gui.AnchorPoint.Y + 0.5, 0, 1))
		gui.Position = u2(gui.Position.X.Scale, 0, clamp(gui.Position.Y.Scale + 0.5, 0, 1), 0)

		return gui
	end;

	-- property application
	["Fill Size"] = function(gui)
		gui.Size = u2(1, 0, 1, 0)
		gui.Position = u2()
		gui.AnchorPoint = v2()

		return gui
	end;

	["Remove Border"] = function(gui)
		gui.BorderSizePixel = 0

		return gui
	end;

	["Make Transparent w/ No Border"] = function(gui)
		gui.BackgroundTransparency = 1
		gui.BorderSizePixel = 0

		return gui
	end;

	-- instance insertion
	["Insert Vertical List"] = function(gui)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Vertical
		list.Parent = gui

		return list
	end;

	["Insert Horizontal List"] = function(gui)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.Parent = gui

		return list
	end;

	["Insert Vertical Scrolling Frame"] = function(gui)
		local frame = Instance.new("ScrollingFrame")
		frame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.ScrollingDirection = Enum.ScrollingDirection.Y
		frame.ScrollBarThickness = 8
		frame.CanvaseSize = u2()
		frame.Parent = gui

		return frame
	end;

	["Insert Horizontal Scrolling Frame"] = function(gui)
		local frame = Instance.new("ScrollingFrame")
		frame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.ScrollingDirection = Enum.ScrollingDirection.X
		frame.ScrollBarThickness = 8
		frame.CanvaseSize = u2()
		frame.Parent = gui

		return frame
	end;

	["Padding (5px, all directions)"] = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = u2(0, 5)
		padding.PaddingTop = u2(0, 5)
		padding.PaddingLeft = u2(0, 5)
		padding.PaddingRight = u2(0, 5)

		return padding
	end;

	["Padding (10px, all directions)"] = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = u2(0, 10)
		padding.PaddingTop = u2(0, 10)
		padding.PaddingLeft = u2(0, 10)
		padding.PaddingRight = u2(0, 10)

		return padding
	end;

	["Padding (15px, all directions)"] = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = u2(0, 15)
		padding.PaddingTop = u2(0, 15)
		padding.PaddingLeft = u2(0, 15)
		padding.PaddingRight = u2(0, 15)

		return padding
	end;

	["Grid (100x100)"] = function(gui)
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = u2(0, 5, 0, 5)
		grid.CellSize = u2(0, 100, 0, 100)
		grid.Parent = gui

		return grid
	end;

	["Gotham Label"] = function(gui)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = c3(255, 255, 255)
		label.TextScaled = true
		label.Size = u2(1, 0, 1, 0)
		label.Parent = gui

		return label
	end;

	["Create Hitbox"] = function(gui)
		local button = Instance.new("TextButton")
		button.Size = u2(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.Name = "Hitbox"
		button.Parent = gui

		return button
	end;
}

return shortcuts