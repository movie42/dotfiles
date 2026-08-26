---
name: apple-calendar
description: Add events to the macOS Calendar app (Apple Calendar) via AppleScript. Use when the user wants to create/register a calendar event, appointment, reminder-as-event, or meeting on their Mac — triggers include "애플 캘린더에 등록", "add to my calendar", "일정 잡아줘", "캘린더에 넣어줘". macOS only.
argument-hint: [title] [date/time] [optional: location, calendar, alarm]
user-invocable: true
---

# apple-calendar

Create events in the local macOS **Calendar** app using AppleScript (`osascript`).
No account login is required — this controls the Calendar app directly on the Mac.

## Requirements & scope

- **macOS only.** Works only where a local shell can run `osascript` — i.e. Claude
  Code CLI or the Claude desktop app running on this Mac. It cannot work from
  claude.ai web, mobile, or Slack (no access to the Mac's shell).
- First run may prompt for **Automation permission** (System Settings → Privacy &
  Security → Automation → allow controlling "Calendar"). If a call fails with a
  `-1743` / "Not authorized" error, tell the user to approve that prompt and retry.

## Execution steps

### Step 1 — Collect event details

Required:
- **Title**
- **Start** date & time

Optional (ask only if the user's intent implies them; don't over-interrogate):
- End time (default: start + 1 hour)
- All-day? (yes/no)
- Location
- Notes
- Alarm (minutes before start)
- Target calendar

If the user gave complete, explicit details, proceed. If key info is missing or
ambiguous (e.g. "다음 주 화요일" with no time), resolve it: compute the absolute
date from today's date and confirm the interpreted date/time in Step 3.

### Step 2 — (Optional) Pick the calendar

If the user named a calendar, use it. If they didn't and you want to confirm the
target, list available calendars:

```bash
osascript ~/.claude/skills/apple-calendar/scripts/list_calendars.applescript
```

Otherwise omit `--calendar` and the event lands in the first **writable** calendar.

### Step 3 — Confirm, then create

Before running, show the user a one-line summary of what will be created
(**title · absolute date/time · calendar · alarm**) when any detail was inferred
rather than explicitly stated. Skip confirmation only when every detail was given
explicitly.

Run the helper script:

```bash
bash ~/.claude/skills/apple-calendar/scripts/add_event.sh \
  --title "Team sync" \
  --start "2026-07-10 14:00" \
  --end   "2026-07-10 15:00" \
  --location "Zoom" \
  --alarm 10 \
  --calendar "Work"
```

On success the script prints `OK\tcalendar=<name>\tuid=<id>`.

### Step 4 — Report

Confirm to the user what was created (title, final date/time, which calendar).
If an alarm/location was set, mention it.

## Argument reference

| Flag | Meaning | Default |
|---|---|---|
| `--title` | Event title (required) | — |
| `--start` | `"YYYY-MM-DD HH:MM"` (or `"YYYY-MM-DD"` for all-day) (required) | — |
| `--end` | `"YYYY-MM-DD HH:MM"` | start + 1 hour |
| `--all-day` | Flag; makes it an all-day event | off |
| `--location` | Location text | none |
| `--notes` | Notes / description | none |
| `--alarm` | Alert N minutes before start | none |
| `--calendar` | Target calendar name | first writable calendar |

## Notes

- Dates are set component-by-component inside AppleScript, so locale/date-format
  settings on the Mac don't matter.
- Arguments are passed via `on run argv`, so titles/notes with quotes, apostrophes,
  or other special characters are safe — no manual escaping needed.
- All-day events: pass `--all-day` and a `--start` date; `--end` defaults to the
  same day.
