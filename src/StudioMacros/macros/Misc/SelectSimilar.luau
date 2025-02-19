return {
	Name = "Select Similar";
	Description = "Select similar instances within an optional range.";

	Predicate = function(gui)
		return gui ~= nil
	end;

	Macro = function(gui)
		--[[
			command.new(function(parts, dist)
				local colors = {}
				local origin = Vector3.new()
				dist = tonumber(dist)
				for _, part in pairs(parts) do
					colors[part.BrickColor.Name] = true
					origin = origin + (part.Position / #parts)
				end

				local newParts = {}
				for i, part in next, getAllParts(workspace) do
					if (dist and (origin - part.Position).magnitude <= dist or not dist) and not selection:getObject(part) then
						if colors[part.BrickColor.Name] then
							table.insert(newParts, part)
						end
					end
				end
				selection:addParts(newParts)
			end, "Select Similar: Color [optional range]", "Select Similar: Color` +[0-9.]+");

			command.new(function(parts, dist)
				local materials = {}
				local origin = Vector3.new()
				dist = tonumber(dist)
				for _, part in pairs(parts) do
					materials[part.Material.Name] = true
					origin = origin + (part.Position / #parts)
				end

				local newParts = {}
				for i, part in next, getAllParts(workspace) do
					if (dist and (origin - part.Position).magnitude <= dist or not dist) and not selection:getObject(part) then
						if materials[part.Material.Name] then
							table.insert(newParts, part)
						end
					end
				end
				selection:addParts(newParts)
			end, "Select Similar: Material [optional range]", "Select Similar: Material` +[0-9.]+");

			command.new(function(parts, dist)
				local materials = {}
				local colors = {}
				local origin = Vector3.new()
				dist = tonumber(dist)
				for _, part in pairs(parts) do
					materials[part.Material.Name] = true
					colors[part.BrickColor.Name] = true
					origin = origin + (part.Position / #parts)
				end

				local newParts = {}
				for i, part in next, getAllParts(workspace) do
					if (dist and (origin - part.Position).magnitude <= dist or not dist) and not selection:getObject(part) then
						if materials[part.Material.Name] and colors[part.BrickColor.Name] then
							table.insert(newParts, part)
						end
					end
				end
				selection:addParts(newParts)
			end, "Select Similar: Appearance [optional range]", "Select Similar: Appearance` +[0-9.]+");

			command.new(function(parts, dist)
				local sizes = {}
				local origin
				dist = tonumber(dist)
				for i, part in next, parts do
					if #sizes > 0 then
						for _, size in next, sizes do
							if part.Size:isClose(size, ISCLOSE_EPSILON) then
								break
							else
								sizes[#sizes + 1] = {part.Size, part.Shape}
								break
							end
						end
					else
						sizes[#sizes + 1] = {part.Size, part.Shape}
						origin = part.Position
					end
				end
				local newParts = {}
				for i, part in next, getAllParts(workspace) do
					if (dist and (origin - part.Position).magnitude <= dist or not dist) and not selection:getObject(part) then
						for _, size in next, sizes do
							if part.Size == size[1] and part.Shape == size[2] then
								table.insert(newParts, part)
							end
						end
					end
				end
				selection:addParts(newParts)
			end, "Select Similar: Size [optional range]", "Select Similar: Size` +[0-9.]+");

			command.new(function(parts, dist)
				local propsList = {}
				local origin
				dist = tonumber(dist)
				for i, part in next, parts do
					if #propsList > 0 then
						for _, props in next, propsList do
							if partMatch(part, props) then
								break
							else
								propsList[#propsList + 1] = {
									["Size"] = part.Size;
									["Shape"] = part.ClassName == "Part" and part.Shape;
									["ClassName"] = part.ClassName;
									["BrickColor"] = part.BrickColor;
									["Material"] = part.Material;
								}
								break
							end
						end
					else
						propsList[#propsList + 1] = {
							["Size"] = part.Size;
							["Shape"] = part.ClassName == "Part" and part.Shape;
							["ClassName"] = part.ClassName;
							["BrickColor"] = part.BrickColor;
							["Material"] = part.Material;
						}
						origin = part.Position
					end
				end
				local newParts = {}
				for i, part in next, getAllParts(workspace) do
					if (dist and (origin - part.Position).magnitude <= dist or not dist) and not selection:getObject(part) then
						for _, props in next, propsList do
							if partMatch(part, props) then
								table.insert(newParts, part)
							end
						end
					end
				end
				selection:addParts(newParts)
			end, "Select Similar: All [optional range]", "Select Similar: All` +[0-9.]+");
		--]]
	end;
}