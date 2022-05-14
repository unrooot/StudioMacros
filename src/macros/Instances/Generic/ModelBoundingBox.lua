return {
	name = "Model boundingbox Generator";
	desc = "[StudioMacros] Generates a boundingbox for models.";
	func = function(model: Instance)
        if model:IsA("Model") then
            local orientation, size = model:GetBoundingBox()

            local boundingBoxPart = Instance.new("Part")
            boundingBoxPart.Anchored = true
            boundingBoxPart.Size = size
            boundingBoxPart.CFrame = orientation
            boundingBoxPart.Name = "BoundingBox"
            boundingBoxPart.Color = Color3.fromRGB(50, 245, 50)
            boundingBoxPart.Transparency = 0.75
            boundingBoxPart.Parent = model

            model.PrimaryPart = boundingBoxPart
        end
	end;
}