-- PogMacros shortcuts file

local ud = UDim.new
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

	["Fill Horizontal"] = function(gui)
		gui.Size = u2(1, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)

		return gui
	end;

	["Fill Vertical"] = function(gui)
		gui.Size = u2(gui.Size.X.Scale, gui.Size.X.Offset, 1, 0)

		return gui
	end;

	["Remove Border"] = function(gui)
		gui.BorderSizePixel = 0

		return gui
	end;

	["Make Frame w/ No Border"] = function(gui)
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.Size = u2(0, 100, 0, 100)
		frame.BackgroundColor3 = c3(255, 255, 255)
		frame.Parent = gui

		game:GetService("Selection"):Set({frame})

		return frame
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

		game:GetService("Selection"):Set({list})

		return list
	end;

	["Insert Horizontal List"] = function(gui)
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.Parent = gui

		game:GetService("Selection"):Set({list})

		return list
	end;

	["Insert Vertical Scrolling Frame"] = function(gui)
		local frame = Instance.new("ScrollingFrame")
		frame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.ScrollingDirection = Enum.ScrollingDirection.Y
		frame.ScrollBarThickness = 8
		frame.CanvasSize = u2()
		frame.Parent = gui

		game:GetService("Selection"):Set({frame})

		return frame
	end;

	["Insert Horizontal Scrolling Frame"] = function(gui)
		local frame = Instance.new("ScrollingFrame")
		frame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		frame.ScrollingDirection = Enum.ScrollingDirection.X
		frame.ScrollBarThickness = 8
		frame.CanvasSize = u2()
		frame.Parent = gui

		game:GetService("Selection"):Set({frame})

		return frame
	end;

	["Padding (5px, all directions)"] = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = ud(0, 5)
		padding.PaddingTop = ud(0, 5)
		padding.PaddingLeft = ud(0, 5)
		padding.PaddingRight = ud(0, 5)
		padding.Parent = gui

		game:GetService("Selection"):Set({padding})

		return padding
	end;

	["Padding (10px, all directions)"] = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = ud(0, 10)
		padding.PaddingTop = ud(0, 10)
		padding.PaddingLeft = ud(0, 10)
		padding.PaddingRight = ud(0, 10)
		padding.Parent = gui

		game:GetService("Selection"):Set({padding})

		return padding
	end;

	["Padding (15px, all directions)"] = function(gui)
		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = ud(0, 15)
		padding.PaddingTop = ud(0, 15)
		padding.PaddingLeft = ud(0, 15)
		padding.PaddingRight = ud(0, 15)
		padding.Parent = gui

		game:GetService("Selection"):Set({padding})

		return padding
	end;

	["Grid (100x100)"] = function(gui)
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = u2(0, 5, 0, 5)
		grid.CellSize = u2(0, 100, 0, 100)
		grid.Parent = gui

		game:GetService("Selection"):Set({grid})

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

		game:GetService("Selection"):Set({label})

		return label
	end;

	["Create Hitbox"] = function(gui)
		local button = Instance.new("TextButton")
		button.Size = u2(1, 0, 1, 0)
		button.BackgroundTransparency = 1
		button.Text = ""
		button.Name = "button"
		button.Parent = gui

		game:GetService("Selection"):Set({button})

		return button
	end;
}

return shortcuts