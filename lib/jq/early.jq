# Rendering helpers for EARLY (https://early.app) time-tracking data.
#
# EARLY timestamps are UTC with millisecond precision and no zone marker
# (e.g. "2026-11-08T16:30:15.563").

# Converts an EARLY timestamp to epoch seconds. Drops the fractional
# seconds, which do not matter at the precision we report.
def early_ts_to_secs:
  .[0:19] + "Z" | fromdateiso8601
  ;

# Formats a number of hours with exactly one decimal place (e.g. 9 -> "9.0").
def fmt_hours:
  (. * 10 | round) as $tenths |
  "\($tenths / 10 | floor).\($tenths % 10)"
  ;

# Formats a part of a whole as a whole-number percentage.
def fmt_pct($total):
  if $total > 0 then "\(. / $total * 100 | round)%" else "0%" end
  ;

# Returns the hours an entry spent inside [$start_secs, $end_secs). Entries
# that cross a boundary are clipped. A running entry (no stoppedAt) counts
# up to now.
def entry_hours($start_secs; $end_secs):
  ([(.duration.startedAt | early_ts_to_secs), $start_secs] | max) as $from |
  ([(.duration.stoppedAt | if . then early_ts_to_secs else now end),
    $end_secs] | min) as $to |
  ([$to - $from, 0] | max) / 3600
  ;

# Expects a time-entries response ({"timeEntries": [...]}). Renders a
# Markdown table of hours grouped by folder, with a row per activity under
# each folder. Activities are grouped by id, since two folders can hold
# activities with the same name.
#
# $folders: a folders response ({"folders": [...]}), used to name folders.
# $range_start, $range_end: the reporting window as EARLY timestamps.
#
# Emits an empty string when no time falls inside the window.
def time_entries_response_to_md($folders; $range_start; $range_end):
  ($folders.folders | map({key: (.id | tostring), value: .name})
    | from_entries) as $folder_names |
  ($range_start | early_ts_to_secs) as $start_secs |
  ($range_end | early_ts_to_secs) as $end_secs |
  [ .timeEntries[] |
    {
      folder: ($folder_names[.activity.folderId // "" | tostring] // "Other"),
      activity_id: .activity.id,
      activity: .activity.name,
      hours: entry_hours($start_secs; $end_secs)
    } |
    select(.hours > 0)
  ] as $rows |
  ($rows | map(.hours) | add // 0) as $total |
  if $total == 0 then ""
  else
    [ $rows | group_by(.folder)[] |
      {
        name: .[0].folder,
        hours: (map(.hours) | add),
        activities: [
          group_by(.activity_id)[] |
          {name: .[0].activity, hours: (map(.hours) | add)}
        ] | sort_by(-.hours, .name)
      }
    ] | sort_by(-.hours, .name) |
    [
      "| Folder / Activity | Hours | % |",
      "| --- | ---: | ---: |",
      ( .[] |
        "| **\(.name)** | **\(.hours | fmt_hours)** " +
          "| **\(.hours | fmt_pct($total))** |",
        ( .activities[] |
          "| \(.name) | \(.hours | fmt_hours) | \(.hours | fmt_pct($total)) |"
        )
      ),
      "| **Total** | **\($total | fmt_hours)** | |"
    ] |
    join("\n")
  end
  ;
