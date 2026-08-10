local SelectionUtils = {}

function SelectionUtils.normalizeName(name: string): string
	local normalized = string.match(name, "^(.-)[%s_%-%.]*%d+$")
	if not normalized or normalized == "" then
		normalized = name
	end

	return string.lower(normalized)
end

function SelectionUtils.getSignature(instance: Instance): string
	return `{instance.ClassName}|{SelectionUtils.normalizeName(instance.Name)}`
end

function SelectionUtils.getScopeChain(instance: Instance): { Instance }
	local chain = {}
	local current = instance.Parent

	while current and current ~= game do
		table.insert(chain, current)

		if current:IsA("LayerCollector") then
			break
		end

		current = current.Parent
	end

	return chain
end

function SelectionUtils.collectMatches(scope: Instance, signatures: { [string]: boolean }): { Instance }
	local matches = {}

	for _, descendant in scope:GetDescendants() do
		if signatures[SelectionUtils.getSignature(descendant)] then
			table.insert(matches, descendant)
		end
	end

	return matches
end

function SelectionUtils.findNextScope(
	chain: { Instance },
	signatures: { [string]: boolean },
	startLevel: number,
	previousCount: number
): (number?, { Instance }?)
	for level = startLevel, #chain do
		local matches = SelectionUtils.collectMatches(chain[level], signatures)
		if #matches > previousCount then
			return level, matches
		end
	end

	return nil
end

return SelectionUtils
