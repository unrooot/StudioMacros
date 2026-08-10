return function(require)
	local SimilarSelection = require("SimilarSelection")

	local selector = SimilarSelection.new(false)

	return {
		Name = "Select Similar";
		Description = "Select instances of the same class and name. Run again to widen the search one ancestor at a time.";

		Predicate = function(instance)
			return instance ~= nil and instance.Parent ~= nil and instance.Parent ~= game
		end;

		ToastValue = function()
			return selector:GetToastValue()
		end;

		Macro = function(instance)
			return selector:Run(instance)
		end;
	}
end
