#!/usr/bin/env bash

# date -ju -v-1d -f "%Y-%m-%d" 2022-01-03 "+%Y-%m-%d"

std_date_format="%Y-%m-%d"

do_date_cmd() {
  # BSD date (i.e. MacOS)
  # Don't set the date and output date in UTC
  cmd=(date -ju)
  [[ ${#} > 0 ]] && cmd+=( "${@}")
  "${cmd[@]}"
}

days_ago() {
  local days="${1}"
  local from_date="${2:-}"
  args=( do_date_cmd )
  # Days ago math
  cmd+=( "-v-${days}d" )
  # Input a specific date
  [[ -n "${from_date}" ]] && cmd+=( -f "${std_date_format}" "${from_date}" )
  # Print out the date as YYYY-MM-DD
  cmd+=( "+${std_date_format}")
  "${cmd[@]}"

  # # BSD date (i.e. MacOS)
  # # Don't set the date and output date in UTC
  # cmd=( date -ju )
  # # Days ago math
  # cmd+=( "-v-${days}d" )
  # # Input a specific date
  # [[ -n "${from_date}" ]] && cmd+=( -f "${std_date_format}" "${from_date}" )
  # # Print out the date as YYYY-MM-DD
  # cmd+=( "+${std_date_format}")
  # "${cmd[@]}"
}

beginning_of_week(){
  # Beginning of this week. It will return today, if today is Monday.
  mon

}

last_week_started_on() {

}

