local ExpressionUtils = {}

local OPERATORS = {
	["+"] = { Precedence = 1; Apply = function(a, b) return a + b end };
	["-"] = { Precedence = 1; Apply = function(a, b) return a - b end };
	["*"] = { Precedence = 2; Apply = function(a, b) return a * b end };
	["/"] = { Precedence = 2; Apply = function(a, b) return a / b end };
	["%"] = { Precedence = 2; Apply = function(a, b) return a % b end };
	["^"] = { Precedence = 3; RightAssociative = true; Apply = function(a, b) return a ^ b end };
}

local function tokenize(text: string)
	local tokens = {}
	local index = 1

	while index <= #text do
		local character = string.sub(text, index, index)

		if string.match(character, "%s") then
			index += 1
			continue
		end

		local number = string.match(text, "^%d*%.?%d+", index)
		if number then
			table.insert(tokens, { Type = "number"; Value = tonumber(number) })
			index += #number
			continue
		end

		local name = string.match(text, "^%a[%w_]*", index)
		if name then
			table.insert(tokens, { Type = "name"; Value = string.lower(name) })
			index += #name
			continue
		end

		if character == "(" or character == ")" then
			table.insert(tokens, { Type = character })
		elseif OPERATORS[character] then
			table.insert(tokens, { Type = "operator"; Value = character })
		else
			return nil, `unexpected '{character}'`
		end

		index += 1
	end

	return tokens
end

local parseExpression

local function parsePrimary(state)
	local token = state.Tokens[state.Index]
	if not token then
		return nil, "unexpected end of expression"
	end

	state.Index += 1

	if token.Type == "number" then
		return token.Value
	elseif token.Type == "name" then
		local value = state.Variables[token.Value]
		if not value then
			return nil, `unknown value '{token.Value}'`
		end

		return value
	elseif token.Type == "(" then
		local value, parseError = parseExpression(state, 1)
		if parseError then
			return nil, parseError
		end

		local closing = state.Tokens[state.Index]
		if not closing or closing.Type ~= ")" then
			return nil, "missing ')'"
		end

		state.Index += 1

		return value
	end

	return nil, `unexpected '{token.Value or token.Type}'`
end

local function parseUnary(state)
	local token = state.Tokens[state.Index]

	if token and token.Type == "operator" and (token.Value == "-" or token.Value == "+") then
		state.Index += 1

		local value, parseError = parseUnary(state)
		if parseError then
			return nil, parseError
		end

		return token.Value == "-" and -value or value
	end

	return parsePrimary(state)
end

function parseExpression(state, minimumPrecedence: number)
	local left, parseError = parseUnary(state)
	if parseError then
		return nil, parseError
	end

	while true do
		local token = state.Tokens[state.Index]
		if not token or token.Type ~= "operator" then
			break
		end

		local operator = OPERATORS[token.Value]
		if operator.Precedence < minimumPrecedence then
			break
		end

		state.Index += 1

		local nextPrecedence = operator.RightAssociative and operator.Precedence or operator.Precedence + 1
		local right, rightError = parseExpression(state, nextPrecedence)
		if rightError then
			return nil, rightError
		end

		left = operator.Apply(left, right)
	end

	return left
end

function ExpressionUtils.evaluate(text: string, variables: { [string]: number }?): (number?, string?)
	if type(text) ~= "string" or string.match(text, "^%s*$") then
		return nil, "empty expression"
	end

	local tokens, tokenizeError = tokenize(text)
	if not tokens then
		return nil, tokenizeError
	end

	local state = {
		Index = 1;
		Tokens = tokens;
		Variables = variables or {};
	}

	local value, parseError = parseExpression(state, 1)
	if parseError then
		return nil, parseError
	end

	local trailing = state.Tokens[state.Index]
	if trailing then
		return nil, `unexpected '{trailing.Value or trailing.Type}'`
	end

	if value ~= value or value == math.huge or value == -math.huge then
		return nil, "result is not a number"
	end

	return value
end

return ExpressionUtils
