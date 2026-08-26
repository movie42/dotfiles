-- add_event.applescript
-- Creates an event in the macOS Calendar app.
-- Arguments are passed positionally via `on run argv` so no string escaping is
-- needed on the caller side. Dates are set component-by-component to avoid any
-- locale-dependent date-string parsing.
--
-- argv order (16 items, all strings):
--   1  title
--   2  calendar name  ("" = auto-pick first writable calendar)
--   3  start year
--   4  start month
--   5  start day
--   6  start hour
--   7  start minute
--   8  end year
--   9  end month
--  10  end day
--  11  end hour
--  12  end minute
--  13  location       ("" = none)
--  14  notes          ("" = none)
--  15  all-day        ("true" | "false")
--  16  alarm minutes  ("" = none; N = alert N minutes before start)

on run argv
	set theTitle to item 1 of argv
	set calName to item 2 of argv
	set sy to (item 3 of argv) as integer
	set sMo to (item 4 of argv) as integer
	set sd to (item 5 of argv) as integer
	set sh to (item 6 of argv) as integer
	set smi to (item 7 of argv) as integer
	set ey to (item 8 of argv) as integer
	set eMo to (item 9 of argv) as integer
	set ed to (item 10 of argv) as integer
	set eh to (item 11 of argv) as integer
	set emi to (item 12 of argv) as integer
	set theLocation to item 13 of argv
	set theNotes to item 14 of argv
	set isAllDay to ((item 15 of argv) is "true")
	set alarmStr to item 16 of argv

	-- Build start date. Set day to 1 first so changing the month never overflows
	-- (e.g. going from a 31st to February).
	set theStart to (current date)
	set day of theStart to 1
	set year of theStart to sy
	set month of theStart to sMo
	set day of theStart to sd
	set hours of theStart to sh
	set minutes of theStart to smi
	set seconds of theStart to 0

	set theEnd to (current date)
	set day of theEnd to 1
	set year of theEnd to ey
	set month of theEnd to eMo
	set day of theEnd to ed
	set hours of theEnd to eh
	set minutes of theEnd to emi
	set seconds of theEnd to 0

	tell application "Calendar"
		-- Resolve the target calendar.
		if calName is "" then
			set theCal to missing value
			repeat with c in calendars
				try
					if writable of c then
						set theCal to c
						exit repeat
					end if
				end try
			end repeat
			if theCal is missing value then set theCal to calendar 1
		else
			set theCal to calendar calName
		end if

		tell theCal
			if isAllDay then
				set newEvent to make new event with properties {summary:theTitle, start date:theStart, end date:theEnd, allday event:true}
			else
				set newEvent to make new event with properties {summary:theTitle, start date:theStart, end date:theEnd}
			end if
			if theLocation is not "" then set location of newEvent to theLocation
			if theNotes is not "" then set description of newEvent to theNotes
			if alarmStr is not "" then
				tell newEvent
					make new display alarm at end of display alarms with properties {trigger interval:-(alarmStr as integer)}
				end tell
			end if
		end tell
		set eventUID to uid of newEvent
		set calTitle to title of theCal
	end tell

	return "OK\tcalendar=" & calTitle & "\tuid=" & eventUID
end run
