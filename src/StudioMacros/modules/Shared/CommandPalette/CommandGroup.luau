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
	self.LayoutOrder = self._maid:Add(ValueObject.new(0))

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

	local revealedCount = 0
	local lastEntryCount = 0

	self._maid:GiveTask(Blend.Computed(percentAlpha, function(percent)
		local entries = self._entries:GetList()
		local entryCount = #entries
		local divisor = math.max(1, entryCount)

		local target = math.clamp(math.floor((percent - 1e-2) * divisor) + 1, 0, entryCount)

		if entryCount ~= lastEntryCount then
			lastEntryCount = entryCount
			revealedCount = 0

			for index, entry in entries do
				entry:SetVisible(index <= target)
			end

			revealedCount = target
			return
		end

		if target > revealedCount then
			for index = revealedCount + 1, target do
				entries[index]:SetVisible(true)
			end
		elseif target < revealedCount then
			for index = revealedCount, target + 1, -1 do
				entries[index]:SetVisible(false)
			end
		end

		revealedCount = target
	end):Subscribe())

	local transparency = Blend.Computed(percentAlpha, function(percent)
		return 1 - percent
	end)

	local groupFrame = self._maid:Add(Blend.State(nil))

	local targetParent = Blend.Computed(props.TargetParent, groupFrame, function(target, frame)
		return target or frame
	end)

	return Blend.New "Frame" {
		Name = "CommandGroup";
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundTransparency = 1;
		LayoutOrder = self.LayoutOrder;
		Size = UDim2.fromScale(1, 0);

		Visible = Blend.Computed(props.TargetParent, props.CustomResult, props.Enabled, function(target, customResult, isEnabled)
			if customResult then
				return isEnabled
			elseif not target then
				return true
			end

			return false
		end);

		Blend.New "UIListLayout" {
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Padding = UDim.new(0, 3);
			VerticalAlignment = Enum.VerticalAlignment.Center;
		};

		[Blend.Instance] = function(frame)
			self._groupFrame = frame
			groupFrame.Value = frame
		end;

		self._entries:ObserveItemsBrio():Pipe({
			RxBrioUtils.map(function(entry)
				return entry:Render({
					CustomResult = props.CustomResult;
					Enabled = props.Enabled;
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