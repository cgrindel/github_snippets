#!/usr/bin/env bash

# date -ju -v-1d -f "%Y-%m-%d" 2022-01-03 "+%Y-%m-%d"

std_date_format="%Y-%m-%d"
std_date_format_output="+${std_date_format}"
# Add input value after expanding these args
std_date_format_input_args=(-f "${std_date_format}")

# Detect which `date` implementation is on PATH. BSD `date` (the macOS
# system binary) uses `-j`/`-v`; GNU `date` (Linux, or Homebrew's
# coreutils gnubin shadowing the system binary on macOS) uses `-d` and
# rejects the BSD flags. Only GNU `date` understands `--version`.
date_bin="date"
if "${date_bin}" --version >/dev/null 2>&1; then
  date_flavor="gnu"
else
  date_flavor="bsd"
fi

do_date_cmd() {
  if [[ ${date_flavor} == "bsd" ]]; then
    # BSD date (i.e. macOS): don't set the date, operate in UTC, and
    # pass the BSD-style flags straight through.
    "${date_bin}" -ju "${@}"
    return
  fi
  _do_date_cmd_gnu "${@}"
}

# Translate the BSD-style argument vector used throughout this file into a
# GNU `date` invocation. Supported BSD constructs:
#   -f FORMAT INPUT  parse INPUT (GNU parses ISO dates natively, so the
#                    FORMAT is skipped)
#   -v-mon           adjust to Monday of the current week
#   -v[+-]Nd         add/subtract N days
#   +OUTPUT          output format
_do_date_cmd_gnu() {
  local input_value=""
  local has_input=0
  local output_format=""
  local bow=0
  local -a day_specs=()

  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      -f)
        # BSD form is `-f FORMAT INPUT`; GNU parses ISO dates
        # natively, so skip the format and let INPUT arrive as a
        # positional argument below.
        shift
        ;;
      -v-mon)
        bow=1
        ;;
      -v[+-]*d)
        local off="${1#-v}"
        off="${off%d}"
        day_specs+=("${off} days")
        ;;
      +*)
        output_format="${1}"
        ;;
      *)
        input_value="${1}"
        has_input=1
        ;;
    esac
    shift
  done

  local base="now"
  [[ ${has_input} -eq 1 ]] && base="${input_value}"

  local spec="${base}"
  [[ ${#day_specs[@]} -gt 0 ]] && spec="${spec} ${day_specs[*]}"

  if [[ ${bow} -eq 1 ]]; then
    # GNU date has no "Monday of this week", so compute it: resolve the
    # date, read its ISO weekday (1=Mon..7=Sun), and step back to
    # Monday.
    local resolved dow
    resolved="$("${date_bin}" -u -d "${spec}" "+%Y-%m-%d")"
    dow="$("${date_bin}" -u -d "${resolved}" "+%u")"
    spec="${resolved} -$((dow - 1)) days"
  fi

  if [[ -n ${output_format} ]]; then
    "${date_bin}" -u -d "${spec}" "${output_format}"
  else
    "${date_bin}" -u -d "${spec}"
  fi
}

find_beginning_of_week() {
  local date="${1:-}"
  # Beginning of this week. It will return today, if today is Monday.
  cmd=(do_date_cmd -v-mon)
  [[ -n ${date:-} ]] && cmd+=("${std_date_format_input_args[@]}" "${date}")
  cmd+=("${std_date_format_output}")
  "${cmd[@]}"
}

find_beginning_of_previous_week() {
  local date="${1:-}"
  local beginning_of_week="$(find_beginning_of_week "${date:-}")"
  days_before 7 "${beginning_of_week}"
}

days_math() {
  # E.g. -1, +2
  local days=${1}
  local from_date="${2:-}"
  cmd=(do_date_cmd)
  # Only attempt the math if the days value is greater than 0.
  [[ ${days} != 0 ]] && cmd+=("-v${days}d")
  # Input a specific date
  [[ -n ${from_date} ]] && cmd+=("${std_date_format_input_args[@]}" "${from_date}")
  # Print out the date as YYYY-MM-DD
  cmd+=("${std_date_format_output}")
  # Execute the command
  "${cmd[@]}"
}

days_before() {
  local days=${1}
  local from_date="${2:-}"
  days_math "-${days}" "${from_date:-}"
}

days_after() {
  local days=${1}
  local from_date="${2:-}"
  days_math "+${days}" "${from_date:-}"
}

get_year_from_date() {
  local date="${1}"
  cmd=(do_date_cmd)
  # Input a specific date
  cmd+=("${std_date_format_input_args[@]}" "${date}")
  # Output just the year
  cmd+=("+%Y")
  # Execute the command
  "${cmd[@]}"
}
