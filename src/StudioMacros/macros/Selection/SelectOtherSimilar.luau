return function(require)
	local SimilarSelection = require("SimilarSelection")

	local selector = SimilarSelection.new(true)

	return {
		Name = "Select Other Similar";
		Description = "Select instances of the same class and name, leaving out the ones you started from. Run again to widen the search one ancestor at a time.";

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
