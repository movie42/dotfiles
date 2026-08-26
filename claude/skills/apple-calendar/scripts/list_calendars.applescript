-- list_calendars.applescript
-- Prints one line per calendar: "<writable|readonly>\t<name>".
-- Used to let the user pick a target calendar before creating an event.

tell application "Calendar"
	set out to ""
	repeat with c in calendars
		set w to "readonly"
		try
			if writable of c then set w to "writable"
		end try
		set out to out & w & tab & (title of c) & linefeed
	end repeat
end tell
return out
