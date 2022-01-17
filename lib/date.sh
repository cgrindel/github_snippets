#!/usr/bin/env bash

# date -ju -v-1d -f "%Y-%m-%d" 2022-01-03 "+%Y-%m-%d"

std_date_format="%Y-%m-%d"
std_date_format_output="+${std_date_format}"
# Add input value after expanding these args
std_date_format_input_args=(-f "${std_date_format}")

do_date_cmd() {
  # BSD date (i.e. MacOS)
  # Don't set the date and output date in UTC
  cmd=(date -ju)
  [[ ${#} > 0 ]] && cmd+=( "${@}")
  "${cmd[@]}"
}

find_beginning_of_week(){
  local date="${1:-}"
  # Beginning of this week. It will return today, if today is Monday.
  cmd=( do_date_cmd -v-mon )
  [[ -n "${date:-}" ]] && cmd+=( "${std_date_format_input_args[@]}" "${date}" )
  cmd+=( "${std_date_format_output}" )
  "${cmd[@]}"
}

find_beginning_of_previous_week() {
  local date="${1:-}"
  local beginning_of_week="$( find_beginning_of_week "${date:-}" )"
  days_before 7 "${beginning_of_week}"
}

days_before() {
  local days=${1}
  local from_date="${2:-}"
  args=( do_date_cmd )
  # Days ago math
  cmd+=( "-v-${days}d" )
  # Input a specific date
  [[ -n "${from_date}" ]] && cmd+=( "${std_date_format_input_args[@]}" "${from_date}" )
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

