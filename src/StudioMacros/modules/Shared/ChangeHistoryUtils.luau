local ChangeHistoryService = game:GetService("ChangeHistoryService")

local ChangeHistoryUtils = {}

--[=[
	Ends a recording from `TryBeginRecording`. Only one recording can be open
	in Studio at a time, so if another plugin leaks one, `TryBeginRecording`
	keeps returning nil and our changes would merge into the surrounding undo
	steps. In that case a waypoint is set instead so Ctrl+Z still undoes just
	this change.
]=]
function ChangeHistoryUtils.finishRecording(name: string, recording: string?, success: boolean)
	if recording then
		local operation = if success then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		ChangeHistoryService:FinishRecording(recording, operation)
	else
		ChangeHistoryService:SetWaypoint(name)
	end
end

--[=[
	Runs `callback` as a single undo step. The recording is finished even if
	`callback` errors, since a recording left open blocks every later one.
]=]
function ChangeHistoryUtils.record(name: string, callback: () -> ())
	local recording = ChangeHistoryService:TryBeginRecording(name)
	local success, err = xpcall(callback, debug.traceback)

	ChangeHistoryUtils.finishRecording(name, recording, success)

	if not success then
		error(err, 0)
	end
end

return ChangeHistoryUtils
