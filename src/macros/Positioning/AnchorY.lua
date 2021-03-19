return {
	name = "Cycle AnchorPoint Y";
	desc = "[StudioMacros] Cycles the current object's AnchorPoint.Y between 0, 0.5, and 1";
	func = function(gui)
        local point = gui.AnchorPoint.Y
        
        if point < 0 or point >= 1 then
            point = 0
        elseif point < 0.5 then
            point = 0.5
        elseif point >= 0.5 and point <= 1 then
            point = 1
        end
        
		gui.AnchorPoint = Vector2.new(gui.AnchorPoint.X, point)
	end;
}