local require = require(script.Parent.loader).load(script)

local AccelTween = require("AccelTween")
local BasicPane = require("BasicPane")
local Blend = require("Blend")
local CommandEntry = require("CommandEntry")
local ObservableList = require("ObservableList")
local RxBrioUtils = require("RxBrioUtils")
local Signal = require("Signal")
local StepUtils = require("StepUtils")
local ValueObject = require("ValueObject")

local CommandGroup = setmetatable({}, BasicPane)
CommandGroup.ClassName = "CommandGroup"
CommandGroup.__index = CommandGroup

function CommandGroup.new()
	local self = setmetatable(BasicPane.new(), CommandGroup)

	self._entries = self._maid:Add(ObservableList.new())
	self._groupCollapsed = self._maid:Add(ValueObject.new(false))
	self._percentAlphaValue = self._maid:Add(ValueObject.new(0, "number"))
	self._percentVisibleTarget = self._maid:Add(ValueObject.new(0, "number"))

	self.Activated = self._maid:Add(Signal.new())
	self.LayoutOrder = self._maid:Add(ValueObject.new(0))

	self._percentAlpha = AccelTween.new(1000)
	self._startAlphaAnimation, self._maid._stopAlphaAnimation = StepUtils.bindToRenderStep(function()
		local animating = self._percentAlpha.rtime > 0
		self._percentAlphaValue.Value = animating and self._percentAlpha.p or self._percentAlpha.t

		return animating
	end)

	self._maid:GiveTask(self.VisibleChanged:Connect(function(isVisible, doNotAnimate)
		local percentVisible = isVisible and 1 or 0

		self._percentVisibleTarget.Value = percentVisible
		self._percentAlpha:SetTarget(percentVisible, doNotAnimate)

		if doNotAnimate then
			self._percentAlphaValue.Value = percentVisible
		end

		self._startAlphaAnimation()
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
	local percentAlpha = self._percentAlphaValue:Observe()

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

	local transparency = Blend.Computed(percentAlpha, props.Transparency or 0, function(percent, paletteTransparency)
		return math.max(1 - percent, paletteTransparency)
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