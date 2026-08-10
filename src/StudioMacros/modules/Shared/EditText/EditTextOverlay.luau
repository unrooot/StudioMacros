local require = require(script.Parent.loader).load(script)

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")

local Blend = require("Blend")
local Maid = require("Maid")

local DISPLAY_ORDER = 1001
local SCREEN_GUI_NAME = "StudioMacrosEditText"

local EditTextOverlay = {}
EditTextOverlay.ClassName = "EditTextOverlay"
EditTextOverlay.__index = EditTextOverlay

local instance = nil

local staleEditor = CoreGui:FindFirstChild(SCREEN_GUI_NAME)
if staleEditor then
	staleEditor:Destroy()
end

local function isTextObject(gui: Instance): boolean
	return gui:IsA("TextLabel")
		or gui:IsA("TextButton")
		or gui:IsA("TextBox")
end

function EditTextOverlay.get(plugin: Plugin)
	if not instance then
		instance = EditTextOverlay.new(plugin)
	end

	return instance
end

function EditTextOverlay.new(plugin: Plugin)
	local self = setmetatable({}, EditTextOverlay)

	self._maid = Maid.new()
	self._plugin = plugin

	self._maid:GiveTask(plugin.Unloading:Connect(function()
		self:Destroy()
	end))

	return self
end

function EditTextOverlay:Open(target: GuiObject?)
	if self._target then
		return
	end

	local resolved = nil

	for _, selectedInstance in Selection:Get() do
		if isTextObject(selectedInstance) then
			resolved = selectedInstance
			break
		end
	end

	if not resolved and target and isTextObject(target) then
		resolved = target
	end

	if not resolved then
		return
	end

	self._target = resolved

	task.defer(function()
		self:_startSession(resolved)
	end)
end

function EditTextOverlay:Close()
	self:_finish(false)
end

function EditTextOverlay:IsEditing(): boolean
	return self._target ~= nil
end

function EditTextOverlay:_startSession(target)
	if self._target ~= target then
		return
	end

	if not target:IsDescendantOf(game) then
		self._target = nil
		return
	end

	local sessionMaid = Maid.new()
	self._maid._session = sessionMaid

	self._originalText = target.Text

	local originalTextTransparency = target.TextTransparency
	local originalStrokeTransparency = target.TextStrokeTransparency

	target.TextTransparency = 1
	target.TextStrokeTransparency = 1

	sessionMaid:GiveTask(function()
		if target:IsDescendantOf(game) then
			target.TextTransparency = originalTextTransparency
			target.TextStrokeTransparency = originalStrokeTransparency
		end
	end)

	local absolutePosition = target.AbsolutePosition
	local absoluteSize = target.AbsoluteSize
	local anchorPoint = target.AnchorPoint

	sessionMaid:GiveTask(Blend.New "ScreenGui" {
		Name = SCREEN_GUI_NAME;
		DisplayOrder = DISPLAY_ORDER;
		Parent = CoreGui;

		Blend.New "TextBox" {
			Name = "input";
			AutomaticSize = target.TextScaled and Enum.AutomaticSize.None or Enum.AutomaticSize.Y;
			BackgroundTransparency = 1;
			ClearTextOnFocus = false;
			FontFace = target.FontFace;
			Text = self._originalText;
			TextColor3 = target.TextColor3;
			TextScaled = target.TextScaled;
			TextSize = target.TextSize;
			TextWrapped = target.TextWrapped;
			TextXAlignment = target.TextXAlignment;
			TextYAlignment = target.TextYAlignment;

			MultiLine = true;

			RichText = false;

			AnchorPoint = anchorPoint;
			Position = UDim2.fromOffset(
				absolutePosition.X + absoluteSize.X * anchorPoint.X,
				absolutePosition.Y + absoluteSize.Y * anchorPoint.Y
			);
			Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y);

			[Blend.Instance] = function(textBox)
				self._input = textBox
			end;

			[Blend.OnEvent "FocusLost"] = function(enterPressed, inputObject)
				local isCancelled = not enterPressed
					and inputObject ~= nil
					and inputObject.KeyCode == Enum.KeyCode.Escape

				self:_finish(not isCancelled, enterPressed)
			end;
		};
	}:Subscribe())

	sessionMaid:GiveTask(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			self:_finish(false)
			return
		end

		if input.KeyCode ~= Enum.KeyCode.Return and input.KeyCode ~= Enum.KeyCode.KeypadEnter then
			return
		end

		if input:IsModifierKeyDown(Enum.ModifierKey.Shift) then
			return
		end

		self:_finish(true, true)
	end))

	local input = self._input

	task.defer(function()
		RunService.RenderStepped:Wait()

		if self._input == input then
			input:CaptureFocus()
		end
	end)
end

function EditTextOverlay:_finish(commit: boolean, committedWithReturn: boolean?)
	local target = self._target
	if not target then
		return
	end

	local input = self._input
	local originalText = self._originalText
	local newText = input and input.Text

	self._target = nil
	self._input = nil

	if input then
		input:ReleaseFocus(false)
	end

	self._maid._session = nil

	if not commit or not newText or not target:IsDescendantOf(game) then
		return
	end

	if committedWithReturn then
		newText = string.gsub(newText, "\r?\n$", "")
	end

	if newText == originalText then
		return
	end

	local recording = ChangeHistoryService:TryBeginRecording("Edit Text")

	target.Text = newText

	if recording then
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end
end

function EditTextOverlay:Destroy()
	if instance == self then
		instance = nil
	end

	self._target = nil
	self._input = nil
	self._maid:DoCleaning()
end

return EditTextOverlay
