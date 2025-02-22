local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local CommandEntry = require("CommandEntry")
local ObservableList = require("ObservableList")
local Rx = require("Rx")
local RxBrioUtils = require("RxBrioUtils")
local Signal = require("Signal")
local ValueObject = require("ValueObject")

local CommandGroup = setmetatable({}, BasicPane)
CommandGroup.ClassName = "CommandGroup"
CommandGroup.__index = CommandGroup

function CommandGroup.new()
	local self = setmetatable(BasicPane.new(), CommandGroup)

	self._entries = self._maid:Add(ObservableList.new())
	self._groupCollapsed = self._maid:Add(ValueObject.new(false))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0))

	self.Activated = self._maid:Add(Signal.new())

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible)
		self._percentVisibleTarget.Value = isVisible and 1 or 0
	end))

	return self
end

function CommandGroup:SetIsCollapsed(isCollapsed: boolean)
	self._groupCollapsed.Value = isCollapsed
end

function CommandGroup:SetHeader(name: string, icon: string)
	if not name or not icon then
		return
	end

	local entry = self._maid:Add(CommandEntry.new())
	entry:SetIsGroupHeader(true)
	entry:SetGroupName(name)
	entry:SetGroupIcon(icon)

	self._maid:GiveTask(self._entries:Add(entry))

	self._maid:GiveTask(entry.Activated:Connect(function()
		self._groupCollapsed.Value = not self._groupCollapsed.Value
	end))
end

function CommandGroup:AddEntry(macroData)
	if not macroData then
		return
	end

	local entry = self._maid:Add(CommandEntry.new())
	entry:SetName(macroData.Name)
	entry:SetDescription(macroData.Description)

	self._maid:GiveTask(self._entries:Add(entry))

	return entry
end

function CommandGroup:GetEntries()
	return self._entries:GetList()
end

function CommandGroup:IsCollapsed()
	return self._groupCollapsed.Value
end

function CommandGroup:Render(props)
	local target = self._percentVisibleTarget:Observe()

	local percentVisible = Blend.Spring(target, 30, 0.7)
	local percentAlpha = Blend.AccelTween(target, target:Pipe({
		Rx.map(function(value)
			return value == 1 and 400 or 1000
		end)
	}))

	self._maid:GiveTask(Blend.Computed(percentAlpha, function(percent)
		local entries = self._entries:GetList()
		local entryCount = math.max(1, #entries)

		for index, entry in entries do
			local progress = (index - 1) / entryCount + 1e-2
			entry:SetVisible(progress <= percent)
		end
	end):Subscribe())

	local transparency = Blend.Computed(percentAlpha, function(percent)
		return 1 - percent
	end)

	local targetParent = self._maid:Add(Blend.State(nil))

	self._maid:GiveTask(props.TargetParent:Observe():Subscribe(function(target)
		if target == nil then
			targetParent.Value = self._groupFrame
		else
			targetParent.Value = target
		end
	end))

	return Blend.New "Frame" {
		Name = "CommandGroup";
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundTransparency = 1;
		Size = UDim2.fromScale(1, 0);

		Visible = Blend.Computed(props.TargetParent, function(target)
			return target == nil
		end);

		Blend.New "UIListLayout" {
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Padding = UDim.new(0, 3);
			VerticalAlignment = Enum.VerticalAlignment.Center;
		};

		[Blend.Instance] = function(groupFrame)
			self._groupFrame = groupFrame
		end;

		self._entries:ObserveItemsBrio():Pipe({
			RxBrioUtils.map(function(entry)
				return entry:Render({
					EntryHeight = props.EntryHeight;
					FzyConfig = props.FzyConfig;
					GroupCollapsed = self._groupCollapsed;
					SearchQuery = props.SearchQuery;
					TargetParent = targetParent;
					Transparency = transparency;
				})
			end);
		});
	}
end

return CommandGroup