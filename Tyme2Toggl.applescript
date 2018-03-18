#!/usr/bin/osascript
use scripting additions
use framework "Foundation"

# Configuration

property togglAPIToken : "YOUR_API_TOKEN"

# JSON Parsing
-- source: http://macscripter.net/viewtopic.php?id=42517
on convertJSONToAS:jsonStringOrPath isPath:isPath
	if isPath then -- read file as data
		set theData to current application's NSData's dataWithContentsOfFile:jsonStringOrPath
	else -- it's a string, convert to data
		set aString to current application's NSString's stringWithString:jsonStringOrPath
		set theData to aString's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	end if
	-- convert to Cocoa object
	set {theThing, theError} to current application's NSJSONSerialization's JSONObjectWithData:theData options:0 |error|:(reference)
	if theThing is missing value then error (theError's localizedDescription() as text) number -10000
	-- we don't know the class of theThing for coercion, so...
	if (theThing's isKindOfClass:(current application's NSArray)) as integer = 1 then
		return theThing as list
	else
		return item 1 of (theThing as list)
	end if
end convertJSONToAS:isPath:

# Number of seconds since midnight
set today to (weekday of (current date))
set secondsToday to (time of (current date))
set yesterdayNight to (current date) - secondsToday
set yesterdayMorning to yesterdayNight - (24 * 60 * 60)
set dayBeforeYesterdayNight to yesterdayNight - (24 * 60 * 60)
set dayBeforeyesterdayMorning to yesterdayMorning - (24 * 60 * 60)
set nl to "
"

if today is Monday then
	# "*Friday*"
	set fridayNight to (current date) - secondsToday - (48 * 60 * 60)
	set fridayMorning to fridayNight - (24 * 60 * 60)
	FetchTasks(fridayMorning, fridayNight, nl)
	
	# "*Weekend*"
	FetchTasks(fridayNight, yesterdayNight, nl)
else
	# "*Yesterday*"
	FetchTasks(yesterdayMorning, yesterdayNight, nl)
end if

on FetchTasks(startTime, endTime, nl)
	set response to do shell script "curl -u " & togglAPIToken & ":api_token -X GET https://www.toggl.com/api/v8/workspaces"
	set toggl_workspaces to its convertJSONToAS:response isPath:false
	
	tell application "Tyme2"
		GetTaskRecordIDs startDate startTime endDate endTime
		
		set fetchedRecords to fetchedTaskRecordIDs as list
		repeat with recordID in fetchedRecords
			GetRecordWithID recordID
			
			if billed of lastFetchedTaskRecord is false then
				set billed of lastFetchedTaskRecord to true
				set tskDuration to timedDuration of lastFetchedTaskRecord as integer
				set tskNote to note of lastFetchedTaskRecord
				set tskStart to ((timeStart of lastFetchedTaskRecord) as «class isot» as string) & "+01:00"
				set tskStop to ((timeEnd of lastFetchedTaskRecord) as «class isot» as string) & "+01:00"
				set tskID to relatedTaskID of lastFetchedTaskRecord
				set tsk to the first item of (every task of every project whose id = tskID)
				set tskName to name of tsk
				
				if tskName is "Misc" and tskNote is not "" then
					set tskName to tskNote
				end if
				
				set prjID to relatedProjectID of lastFetchedTaskRecord
				set prj to the first item of (every project whose id = prjID)
				set prjName to name of prj
				
				repeat with workspace in toggl_workspaces
					set workspaceName to |name| of workspace
					set workspaceId to |id| of workspace
					if workspaceName is prjName then
						set response to do shell script "curl -u " & togglAPIToken & ":api_token -X GET https://www.toggl.com/api/v8/workspaces/" & workspaceId & "/projects"
						set toggl_projects to (my convertJSONToAS:response isPath:false)
						
						set projId to |id| of first item of toggl_projects
						set response to do shell script "curl -u " & togglAPIToken & ":api_token -H \"Content-Type: application/json\" -d '{\"time_entry\":{\"description\":\"" & tskName & "\",\"duration\": " & tskDuration & " ,\"start\":\"" & tskStart & "\",\"pid\":" & projId & ",\"created_with\":\"Tyme2\"}}' -X POST https://www.toggl.com/api/v8/time_entries"
					end if
				end repeat
			end if
		end repeat
	end tell
end FetchTasks
