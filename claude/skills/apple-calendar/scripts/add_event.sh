#!/usr/bin/env bash
# add_event.sh — parse friendly arguments and create a macOS Calendar event.
#
# Usage:
#   add_event.sh --title "Team sync" --start "2026-07-10 14:00" [options]
#
# Options:
#   --title     STR   Event title                                  (required)
#   --start     STR   "YYYY-MM-DD HH:MM"  (or "YYYY-MM-DD" for all-day)
#   --end       STR   "YYYY-MM-DD HH:MM"  (default: start + 1 hour)
#   --location  STR   Location text
#   --notes     STR   Notes / description
#   --calendar  STR   Target calendar name (default: first writable calendar)
#   --all-day         Make it an all-day event
#   --alarm     N     Alert N minutes before start (e.g. 10)
#
# macOS only. Relies on `date -j -v` and `osascript`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLESCRIPT="$SCRIPT_DIR/add_event.applescript"

TITLE=""
START=""
END=""
LOCATION=""
NOTES=""
CALENDAR=""
ALLDAY="false"
ALARM=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--title)    TITLE="$2";    shift 2;;
		--start)    START="$2";    shift 2;;
		--end)      END="$2";      shift 2;;
		--location) LOCATION="$2"; shift 2;;
		--notes)    NOTES="$2";    shift 2;;
		--calendar) CALENDAR="$2"; shift 2;;
		--all-day)  ALLDAY="true"; shift 1;;
		--alarm)    ALARM="$2";    shift 2;;
		*) echo "Unknown argument: $1" >&2; exit 1;;
	esac
done

if [[ -z "$TITLE" ]]; then echo "Error: --title is required" >&2; exit 1; fi
if [[ -z "$START" ]]; then echo "Error: --start is required" >&2; exit 1; fi

# Normalize: a date without a time component gets midnight.
if [[ "$START" != *" "* ]]; then START="$START 00:00"; fi

# Default end.
if [[ -z "$END" ]]; then
	if [[ "$ALLDAY" == "true" ]]; then
		END="$START"
	else
		END="$(date -j -v+1H -f "%Y-%m-%d %H:%M" "$START" "+%Y-%m-%d %H:%M")"
	fi
else
	if [[ "$END" != *" "* ]]; then END="$END 00:00"; fi
fi

# Split "YYYY-MM-DD HH:MM" into integer components (strip leading zeros).
parse_dt() {
	local dt="$1" y mo d h mi
	IFS=' -:' read -r y mo d h mi <<< "$dt"
	echo "$((10#$y)) $((10#$mo)) $((10#$d)) $((10#$h)) $((10#$mi))"
}

read -r SY SMO SD SH SMI <<< "$(parse_dt "$START")"
read -r EY EMO ED EH EMI <<< "$(parse_dt "$END")"

osascript "$APPLESCRIPT" \
	"$TITLE" "$CALENDAR" \
	"$SY" "$SMO" "$SD" "$SH" "$SMI" \
	"$EY" "$EMO" "$ED" "$EH" "$EMI" \
	"$LOCATION" "$NOTES" "$ALLDAY" "$ALARM"
