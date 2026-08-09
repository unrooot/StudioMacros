local require = require(script.Parent.loader).load(script)

local BasicPane = require("BasicPane")
local Blend = require("Blend")
local MacroToastEntry = require("MacroToastEntry")
local Maid = require("Maid")
local ObservableList = require("ObservableList")
local RxBrioUtils = require("RxBrioUtils")

local BOTTOM_OFFSET = 48
local ENTRY_PADDING = 5
local MAX_ENTRIES = 3

local MacroToast = setmetatable({}, BasicPane)
MacroToast.ClassName = "MacroToast"
MacroToast.__index = MacroToast

function MacroToast.new()
	local self = setmetatable(BasicPane.new(), MacroToast)

	self._entries = self._maid:Add(ObservableList.new())
	self._nextLayoutOrder = 0

	return self
end

function MacroToast:ShowMacro(macroName: string, groupIcon: string?)
	local entries = self._entries:GetList()

	local newest = entries[#entries]
	if newest and newest:IsVisible() and newest:GetMacroName() == macroName then
		newest:Bump()
		return
	end

	local entry = MacroToastEntry.new(macroName, groupIcon)

	self._nextLayoutOrder += 1
	entry.LayoutOrder.Value = self._nextLayoutOrder

	local maid = Maid.new()
	maid:Add(entry)
	maid:GiveTask(self._entries:Add(entry))
	maid:GiveTask(entry.Finished:Connect(function()
		self._maid[entry] = nil

		if #self._entries:GetList() == 0 then
			self:Hide()
		end
	end))

	self._maid[entry] = maid

	self:Show()
	entry:Present()

	self:_trimToCapacity()
end

function MacroToast:_trimToCapacity()
	local showing = {}
	for _, entry in self._entries:GetList() do
		if entry:IsVisible() then
			table.insert(showing, entry)
		end
	end

	for index = 1, #showing - MAX_ENTRIES do
		showing[index]:Dismiss()
	end
end

function MacroToast:Render(props)
	return Blend.New "Frame" {
		Name = "MacroToast";
		AnchorPoint = Vector2.new(0.5, 1);
		BackgroundTransparency = 1;
		Parent = props and props.Parent;
		Position = UDim2.new(0.5, 0, 1, -BOTTOM_OFFSET);
		Visible = self:ObserveVisible();

		Size = UDim2.new(
			1,
			0,
			0,
			(MacroToastEntry.Height * MAX_ENTRIES) + (ENTRY_PADDING * (MAX_ENTRIES - 1))
		);

		Blend.New "UIListLayout" {
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Padding = UDim.new(0, ENTRY_PADDING);
			SortOrder = Enum.SortOrder.LayoutOrder;
			VerticalAlignment = Enum.VerticalAlignment.Bottom;
		};

		self._entries:ObserveItemsBrio():Pipe({
			RxBrioUtils.map(function(entry)
				return entry:Render()
			end);
		});
	}
end

return MacroToast
