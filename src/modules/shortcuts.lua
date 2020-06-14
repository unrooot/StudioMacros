local u2 = UDim2.new
local v2 = Vector2.new
local ud = UDim.new

local Shortcuts = {
	
-- ALIGNMENTS
	["Center"] = function(gui)
		gui.AnchorPoint=v2(0.5,0.5)
		gui.Position=u2(0.5,0,0.5,0)
		return gui
	end,
	
	["Right"] = function(gui)
		gui.AnchorPoint=v2(1,gui.AnchorPoint.Y)
		gui.Position=u2(1,0,gui.Position.Y.Scale,gui.Position.Y.Offset)
		return gui
	end,
	
	["Left"] = function(gui)
		gui.AnchorPoint=v2(0,gui.AnchorPoint.Y)
		gui.Position=u2(0,0,gui.Position.Y.Scale,gui.Position.Y.Offset)
		return gui
	end,
	
	["Top"] = function(gui)
		gui.AnchorPoint=v2(gui.AnchorPoint.X, 0)
		gui.Position=u2(gui.Position.X.Scale,gui.Position.X.Offset,0,0)
		return gui
	end,
	
	["Bottom"] = function(gui)
		gui.AnchorPoint=v2(0,gui.AnchorPoint.X)
		gui.Position=u2(gui.Position.X.Scale,gui.Position.X.Offset,1,0)
		return gui
	end,
	
-- SIZING
	["Max Size"] = function(gui)
		gui.Size=u2(1,0,1,0)
		gui.Position=u2(0,0,0,0)
		gui.AnchorPoint=v2(0,0)
		return gui
	end,
	
-- TRANSPARENCY / BORDER
	["Transparent, No Border"] = function(gui)
		gui.BackgroundTransparency=1
		gui.BorderSizePixel=0
		return gui
	end,
	
	["No Border"] = function(gui)
		gui.BorderSizePixel=0
		return gui
	end,
	
-- LIST LAYOUTS
	["Vertical List"] = function(gui)
		local list=Instance.new("UIListLayout")
		list.FillDirection=Enum.FillDirection.Vertical
		list.Parent=gui
		return list
	end,
	
	["Horizontal List"] = function(gui)
		local list=Instance.new("UIListLayout")
		list.FillDirection=Enum.FillDirection.Horizontal
		list.Parent=gui
		return list
	end,
	
-- SCROLLING FRAMES
	["Vertical Scroller"] = function(gui)
		local scroller=Instance.new("ScrollingFrame")
		scroller.Parent=gui
		scroller.CanvaseSize=u2(0,0,2,0)
		scroller.ScrollingDirection=Enum.ScrollingDirection.Y
		return scroller
	end,
	
	["Horizontal Scroller"] = function(gui)
		local scroller=Instance.new("ScrollingFrame")
		scroller.Parent=gui
		scroller.CanvaseSize=u2(2,0,0,0)
		scroller.ScrollingDirection=Enum.ScrollingDirection.X
		return scroller
	end,
	
-- PADDING
	["Padding-5"] = function(gui)
		local padding=Instance.new("UIPadding")
		padding.Parent=gui
		padding.PaddingBottom=ud(0,5)
		padding.PaddingLeft=ud(0,5)
		padding.PaddingRight=ud(0,5)
		padding.PaddingTop=ud(0,5)
		return padding
	end,
	
	["Padding-10"] = function(gui)
		local padding=Instance.new("UIPadding")
		padding.Parent=gui
		padding.PaddingBottom=ud(0,10)
		padding.PaddingLeft=ud(0,10)
		padding.PaddingRight=ud(0,10)
		padding.PaddingTop=ud(0,10)
		return padding
	end,
	
	["Padding-15"] = function(gui)
		local padding=Instance.new("UIPadding")
		padding.Parent=gui
		padding.PaddingBottom=ud(0,15)
		padding.PaddingLeft=ud(0,15)
		padding.PaddingRight=ud(0,15)
		padding.PaddingTop=ud(0,15)
		return padding
	end,
	
-- GRID
	["Grid-100x100"] = function(gui)
		local grid=Instance.new("UIGridLayout")
		grid.Parent=gui
		grid.CellPadding=u2(0,5,0,5)
		grid.CellSize=u2(0,100,0,100)
		return grid
	end,
	
-- TEXT
	["Gotham Label"] = function(gui)
		local label=Instance.new("TextLabel")
		label.Parent=gui
		label.BackgroundTransparency=1
		label.BorderSizePixel=0
		label.Font=Enum.Font.GothamBlack
		label.TextColor3=Color3.fromRGB(255,255,255)
		label.TextScaled=true
		label.Size=u2(1,0,1,0)
		return label
	end,
	
	["Hitbox"] = function(gui)
		local btn=Instance.new("TextButton")
		btn.Parent=gui
		btn.Size=u2(1,0,1,0)
		btn.BackgroundTransparency=1
		btn.Text=""
		btn.Name="Hitbox"
	end,
	
-- INSERTING
	["New Frame"] = function(gui)
		local frame=Instance.new("Frame")
		frame.Parent=gui
		return frame
	end,
	
	["New Gui"] = function(gui)
		local new=Instance.new("ScreenGui")
		new.Parent=gui
		return new
	end
	
	["New TextButton"] = function(gui)
		local button=Instance.new("TextButton")
		button.Parent=gui
		return button
	end,

-- CORNER
	["New Corner"] = function(gui)
		local corner=Instance.new("UICorner")
		corner.Parent=gui
		return corner
	end
}


return Shortcuts