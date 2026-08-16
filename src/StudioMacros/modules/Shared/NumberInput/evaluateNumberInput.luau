local require = require(script.Parent.loader).load(script)

local ExpressionUtils = require("ExpressionUtils")

--[=[
	Runs typed text through a number input config: the config's optional
	rewrite, then the expression parser with whatever variables the config
	exposes for the target, then the config's optional rejection check.

	@param config table
	@param text string
	@param target Instance?
	@return number?, string? -- the reason it failed, for previewing
]=]
return function(config, text: string, target: Instance?): (number?, string?)
	if config.Sanitize then
		text = config.Sanitize(text)
	end

	local variables = nil
	if config.GetVariables and target then
		variables = config.GetVariables(target)
	end

	local value, evaluateError = ExpressionUtils.evaluate(text, variables)
	if not value then
		return nil, evaluateError
	end

	if config.Validate then
		local isValid, validateError = config.Validate(value)
		if not isValid then
			return nil, validateError or "invalid value"
		end
	end

	return value
end
