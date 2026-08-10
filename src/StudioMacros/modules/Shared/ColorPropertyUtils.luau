local ColorPropertyUtils = {}

local RULES = {
	{ ClassName = "UIStroke"; Property = "Color" };
	{ ClassName = "TextLabel"; Property = "TextColor3" };
	{ ClassName = "TextButton"; Property = "TextColor3" };
	{ ClassName = "TextBox"; Property = "TextColor3" };
	{ ClassName = "ImageLabel"; Property = "ImageColor3" };
	{ ClassName = "ImageButton"; Property = "ImageColor3" };
	{ ClassName = "ViewportFrame"; Property = "ImageColor3" };
	{ ClassName = "GuiObject"; Property = "BackgroundColor3" };
	{ ClassName = "BasePart"; Property = "Color" };
	{ ClassName = "Decal"; Property = "Color3" };
	{ ClassName = "Light"; Property = "Color" };
	{ ClassName = "Highlight"; Property = "FillColor" };
	{ ClassName = "SelectionBox"; Property = "Color3" };
	{ ClassName = "Atmosphere"; Property = "Color" };
}

function ColorPropertyUtils.getProperty(instance: Instance?): string?
	if not instance then
		return nil
	end

	for _, rule in RULES do
		if instance:IsA(rule.ClassName) then
			return rule.Property
		end
	end

	return nil
end

function ColorPropertyUtils.getColor(instance: Instance?): Color3?
	local property = ColorPropertyUtils.getProperty(instance)
	if not property then
		return nil
	end

	local success, value = pcall(function()
		return (instance :: any)[property]
	end)

	if not success or typeof(value) ~= "Color3" then
		return nil
	end

	return value
end

function ColorPropertyUtils.setColor(instance: Instance?, color: Color3): string?
	local property = ColorPropertyUtils.getProperty(instance)
	if not property or ColorPropertyUtils.getColor(instance) == nil then
		return nil
	end

	local target = instance :: any
	target[property] = color

	return property
end

local LABELS = {
	TextColor3 = "Text Color";
	BackgroundColor3 = "Background Color";
	ImageColor3 = "Image Color";
}

function ColorPropertyUtils.getLabel(property: string?): string
	if not property then
		return "Color"
	end

	return LABELS[property] or "Color"
end

return ColorPropertyUtils
