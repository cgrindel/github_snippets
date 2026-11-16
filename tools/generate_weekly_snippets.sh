#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null \
  || source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null \
  || source "$0.runfiles/$f" 2>/dev/null \
  || source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null \
  || source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null \
  || {
    echo >&2 "ERROR: cannot find $f"
    exit 1
  }
f=
set -e
# --- end runfiles.bash initialization v2 ---

# MARK - Locate Deps

fail_sh_location=cgrindel_bazel_starlib/shlib/lib/fail.sh
fail_sh="$(rlocation "${fail_sh_location}")" \
  || (echo >&2 "Failed to locate ${fail_sh_location}" && exit 1)
# shellcheck disable=SC1090
source "${fail_sh}"

github_sh_location=cgrindel_bazel_starlib/shlib/lib/github.sh
github_sh="$(rlocation "${github_sh_location}")" \
  || (echo >&2 "Failed to locate ${github_sh_location}" && exit 1)
# shellcheck disable=SC1090
source "${github_sh}"

date_sh_location=cgrindel_github_snippets/lib/date.sh
date_sh="$(rlocation "${date_sh_location}")" \
  || (echo >&2 "Failed to locate ${date_sh_location}" && exit 1)
# shellcheck disable=SC1090
source "${date_sh}"

github_jq_location=cgrindel_github_snippets/lib/jq/github.jq
github_jq="$(rlocation "${github_jq_location}")" \
  || (echo >&2 "Failed to locate ${github_jq_location}" && exit 1)

# shellcheck disable=SC2153
jq_location="${JQ_BIN#external/}"
jq_bin="$(rlocation "${jq_location}")" \
  || (echo >&2 "Failed to locate ${jq_location}" && exit 1)

# shellcheck disable=SC2153
claude_location="${CLAUDE_BIN#external/}"
claude_bin="$(rlocation "${claude_location}")" \
  || (echo >&2 "Failed to locate ${claude_location}" && exit 1)

summary_prompt_location=cgrindel_github_snippets/lib/claude/summary_prompt.md
summary_prompt_path="$(rlocation "${summary_prompt_location}")" \
  || (echo >&2 "Failed to locate ${summary_prompt_location}" && exit 1)

# shellcheck disable=SC2153
prettier_bin="$(rlocation "${PRETTIER_BIN_RUNFILE}")" \
  || (echo >&2 "Failed to locate ${PRETTIER_BIN_RUNFILE}" && exit 1)

# Resolve the gh binary. Tests inject a stand-in via GH_BIN to stay
# hermetic; normal runs locate the vendored multitool gh through runfiles.
if [[ -n ${GH_BIN:-} ]]; then
  gh="${GH_BIN}"
else
  gh_location=multitool/tools/gh/gh
  gh="$(rlocation "${gh_location}")" \
    || (echo >&2 "Failed to locate ${gh_location}" && exit 1)
fi

# Resolve curl for the EARLY API. Tests inject a stand-in via CURL_BIN;
# normal runs locate the vendored multitool curl through runfiles.
if [[ -n ${CURL_BIN:-} ]]; then
  curl_bin="${CURL_BIN}"
else
  curl_location=multitool/tools/curl/curl
  curl_bin="$(rlocation "${curl_location}")" \
    || (echo >&2 "Failed to locate ${curl_location}" && exit 1)
fi

early_api_url="${EARLY_API_URL:-https://api.early.app/api/v4}"

# MARK - Functions

# Query GitHub's search/issues endpoint, which covers both pull requests
# and issues. The caller supplies the qualifiers (e.g. type:pr, author:...).
#
# The Search API enforces a low rate limit (~30 requests/minute) and a single
# snippet run issues several searches, so retry with exponential backoff when
# GitHub throttles us (HTTP 403/429 "rate limit"). Other failures surface
# immediately.
search_issues() {
  query_args_str="${*}"
  local attempt=1
  local max_attempts=5
  local delay=15
  local out
  while true; do
    if out="$("${gh}" api -X GET search/issues -f q="${query_args_str}" 2>&1)"; then
      printf '%s' "${out}"
      return 0
    fi
    if [[ ${attempt} -ge ${max_attempts} ]] \
      || ! grep -qi "rate limit" <<<"${out}"; then
      echo >&2 "${out}"
      return 1
    fi
    echo >&2 "GitHub rate limit hit; retrying in ${delay}s" \
      "(attempt ${attempt}/${max_attempts})."
    sleep "${delay}"
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
}

# Prints an EARLY credential. Prefers the env var, then falls back to the
# macOS Keychain entry (service name; tests override the tool with
# SECURITY_BIN) created with:
#   security add-generic-password -a "${USER}" -s <service> -w
read_early_credential() {
  local env_value="${1}"
  local keychain_service="${2}"
  if [[ -n ${env_value} ]]; then
    printf '%s' "${env_value}"
    return 0
  fi
  local security_bin="${SECURITY_BIN:-security}"
  command -v "${security_bin}" >/dev/null 2>&1 || return 1
  "${security_bin}" find-generic-password -s "${keychain_service}" -w \
    2>/dev/null
}

# Calls the EARLY API with curl. Reads curl config (e.g. the auth header)
# from stdin so secrets never appear in the process list. Fails on HTTP
# errors.
early_curl() {
  "${curl_bin}" --silent --show-error --fail --config - "${@}"
}

# Fetches the EARLY time entries for the week from local midnight on
# begin_date to local midnight on end_date (both YYYY-MM-DD) and renders them
# as a Markdown table grouped by folder and activity. Prints nothing when no
# time was recorded. Returns non-zero on date, credential or API errors.
# shellcheck disable=SC2016 # jq expressions, not shell expansions
early_time_md() {
  local begin_date="${1}"
  local end_date="${2}"
  local range_start range_end
  local api_key api_secret sign_in_config token auth_config
  local folders_json entries_json

  # errexit is off when the caller tests this function in an `if`, so every
  # step checks its own status.

  # EARLY stores UTC, so convert the local week boundaries.
  range_start="$(local_midnight_to_utc_ts "${begin_date}")" || return 1
  range_end="$(local_midnight_to_utc_ts "${end_date}")" || return 1

  api_key="$(read_early_credential "${EARLY_API_KEY:-}" early-api-key)" \
    || {
      echo >&2 "No EARLY API key found (EARLY_API_KEY or Keychain" \
        "service early-api-key)."
      return 1
    }
  api_secret="$(
    read_early_credential "${EARLY_API_SECRET:-}" early-api-secret
  )" \
    || {
      echo >&2 "No EARLY API secret found (EARLY_API_SECRET or Keychain" \
        "service early-api-secret)."
      return 1
    }

  # Build the curl config from env so the secret never lands on a command
  # line. The body is JSON, then quoted again as a curl config string.
  sign_in_config="$(
    EARLY_KEY="${api_key}" EARLY_SECRET="${api_secret}" "${jq_bin}" -nr \
      '"header = \"Content-Type: application/json\"",
      "data = " + ({apiKey: $ENV.EARLY_KEY, apiSecret: $ENV.EARLY_SECRET}
        | tojson | tojson)'
  )"
  token="$(
    printf '%s\n' "${sign_in_config}" \
      | early_curl -X POST "${early_api_url}/developer/sign-in" \
      | "${jq_bin}" -r '.token // empty'
  )"
  if [[ -z ${token} ]]; then
    echo >&2 "EARLY sign-in did not return a token."
    return 1
  fi

  # Quote the header as a curl config string, passing the token via env.
  auth_config="$(
    EARLY_TOKEN="${token}" "${jq_bin}" -nr \
      '"header = " + ("Authorization: Bearer \($ENV.EARLY_TOKEN)" | tojson)'
  )" || return 1
  folders_json="$(
    printf '%s\n' "${auth_config}" | early_curl "${early_api_url}/folders"
  )" || return 1
  entries_json="$(
    printf '%s\n' "${auth_config}" \
      | early_curl "${early_api_url}/time-entries/${range_start}/${range_end}"
  )" || return 1

  printf '%s' "${entries_json}" \
    | "${jq_bin}" -r -L "${jq_lib_dir}" \
      --argjson folders "${folders_json}" \
      --arg range_start "${range_start}" \
      --arg range_end "${range_end}" \
      'import "early" as early;
      early::time_entries_response_to_md($folders; $range_start; $range_end)'
}

# MARK - Process Args

get_usage() {
  local utility
  utility="$(basename "${BASH_SOURCE[0]}")"
  cat <<-EOF
Generate your weekly snippets using GitHub activity.

Usage:
${utility} [OPTIONS]

Options:
--week_with_date      Optional. Identify the week of snippets by the specified
                      date. It will determine the week that contains the date
                      and generate the snippets for that week.
--author              Optional. The author whose PR activity should be queried.
                      If not specified, the author is determined from the
                      github credentials (gh auth status).
--snippets_dir        Optional. Specifies the directory that contains
                      snippets files (snippets_XXXX.md). If specified, the
                      script will identify the target snippets file, generate
                      the snippets, and add them to front of the file.
--no_launch_vim       Optional. Prevents vim from being launched with the
                      snippets file open.
--no_summary          Optional. Skip the Claude-generated summary pass.
                      Produces an activity-only entry like the old behavior.
--claude_model        Optional. Model id to pass to claude via --model.
                      Defaults to claude-opus-4-7.
--no_format           Optional. Skip the prettier pass that normalizes the
                      year file after prepending the new entry.
--no_time             Optional. Skip the EARLY time-tracking breakdown.
                      Credentials come from EARLY_API_KEY/EARLY_API_SECRET,
                      or the Keychain services early-api-key and
                      early-api-secret.
EOF
}

launch_vim="true"
generate_summary="true"
run_prettier="true"
include_time="true"
claude_model="claude-opus-4-7"

args=()
while (("$#")); do
  case "${1}" in
    "--help")
      show_usage
      exit 0
      ;;
    "--week_with_date")
      week_with_date="${2}"
      shift 2
      ;;
    "--author")
      author="${2}"
      shift 2
      ;;
    "--snippets_dir")
      snippets_dir="${2}"
      shift 2
      ;;
    "--no_launch_vim")
      launch_vim="false"
      shift 1
      ;;
    "--no_summary")
      generate_summary="false"
      shift 1
      ;;
    "--no_format")
      run_prettier="false"
      shift 1
      ;;
    "--no_time")
      include_time="false"
      shift 1
      ;;
    "--claude_model")
      claude_model="${2}"
      shift 2
      ;;
    *)
      args+=("${1}")
      shift 1
      ;;
  esac
done

# MARK - Retrieve the closed PRs for the past week.

jq_lib_dir="$(dirname "${github_jq}")"

cd "${BUILD_WORKSPACE_DIRECTORY}"

# Figure out the author
[[ -z ${author:-} ]] && author="$(get_gh_username)"

# Determine the date range
if [[ -n ${week_with_date:-} ]]; then
  begin_date="$(find_beginning_of_week "${week_with_date}")"
else
  begin_date="$(find_beginning_of_previous_week)"
fi
end_date="$(days_after 7 "${begin_date}")"

# Retrieve the closed PRs
closed_prs_result="$(
  search_issues "type:pr" "state:closed" "author:${author}" \
    "closed:${begin_date}..${end_date}"
)"
closed_prs_md="$(
  echo "${closed_prs_result}" \
    | "${jq_bin}" -r -L "${jq_lib_dir}" \
      'import "github" as github; github::closed_pr_search_response_to_md '
)"

reviewed_prs_result="$(
  search_issues "type:pr" "-author:${author}" "reviewed-by:${author}" \
    "updated:${begin_date}..${end_date}"
)"
reviewed_prs_md="$(
  echo "${reviewed_prs_result}" \
    | "${jq_bin}" -r -L "${jq_lib_dir}" \
      'import "github" as github; github::reviewed_pr_search_response_to_md '
)"

# Retrieve issues the author opened this week.
opened_issues_result="$(
  search_issues "type:issue" "author:${author}" \
    "created:${begin_date}..${end_date}"
)"
opened_issues_md="$(
  echo "${opened_issues_result}" \
    | "${jq_bin}" -r -L "${jq_lib_dir}" \
      'import "github" as github; github::opened_issue_search_response_to_md '
)"

# Retrieve issues the author drove to closure this week. GitHub search has no
# "closed-by" qualifier, so we approximate with issues assigned to the author
# that were closed during the week.
closed_issues_result="$(
  search_issues "type:issue" "assignee:${author}" "state:closed" \
    "closed:${begin_date}..${end_date}"
)"
closed_issues_md="$(
  echo "${closed_issues_result}" \
    | "${jq_bin}" -r -L "${jq_lib_dir}" \
      'import "github" as github; github::closed_issue_search_response_to_md '
)"

# Retrieve issues the author commented on this week. There is no
# "commented-on:<date>" qualifier, so we filter by last-updated like the
# reviewed-PRs query.
commented_issues_result="$(
  search_issues "type:issue" "commenter:${author}" \
    "updated:${begin_date}..${end_date}"
)"
commented_issues_md="$(
  echo "${commented_issues_result}" \
    | "${jq_bin}" -r -L "${jq_lib_dir}" \
      'import "github" as github; github::commented_issue_search_response_to_md '
)"

# Assemble the activity Markdown that Claude will summarize (and that we'll
# emit verbatim in the output below).
activity_md="$(
  cat <<-EOF
## Activity

${closed_prs_md}

${reviewed_prs_md}

${opened_issues_md}

${closed_issues_md}

${commented_issues_md}
EOF
)"

# Retrieve the EARLY time breakdown. A failure here only drops the section;
# it never blocks the snippet.
time_md=""
if [[ ${include_time} == "true" ]]; then
  if early_md="$(early_time_md "${begin_date}" "${end_date}")"; then
    if [[ -n ${early_md} ]]; then
      time_md="## Time

${early_md}"
    fi
  else
    echo >&2 "Warning: EARLY time breakdown failed; omitting the Time" \
      "section. Pass --no_time to skip it."
  fi
fi

# Generate the human-readable summary sections via Claude. Fall back to an
# activity-only entry if Claude errors or is disabled.
summary_md=""
if [[ ${generate_summary} == "true" ]]; then
  prompt="$(cat "${summary_prompt_path}")"
  prompt="${prompt}

${activity_md}
"
  if [[ -n ${time_md} ]]; then
    prompt="${prompt}
${time_md}
"
  fi
  if claude_out="$("${claude_bin}" -p "${prompt}" --model "${claude_model}" 2>&1)"; then
    summary_md="$(printf '%s' "${claude_out}" | sed -e 's/[[:space:]]*$//')"
  else
    echo >&2 "Warning: Claude summary generation failed (exit $?);" \
      "emitting activity-only entry."
    echo >&2 "${claude_out}"
  fi
fi

# Build the entry. When the summary is present, slot it above the activity
# heading; when absent, the activity sits directly under the week heading.
if [[ -n ${summary_md} ]]; then
  summary_block="${summary_md}

"
else
  summary_block=""
fi

# The Time section, when present, follows the activity.
if [[ -n ${time_md} ]]; then
  time_block="

${time_md}"
else
  time_block=""
fi

# Generate the output markdown
week_ending_date="$(days_before 1 "${end_date}")"
snippet_heading="# Week Ending ${week_ending_date}"
output="$(
  cat <<-EOF
${snippet_heading}

${summary_block}${activity_md}${time_block}

---

EOF
)"
# NOTE: If the last line of the here doc above is empty, it will not print the
# blank line.

# If a snippets directory was provided, then look for the snippet file and
# update it.
if [[ -n ${snippets_dir:-} ]]; then
  # Determine the snippet path.
  snippet_year="$(get_year_from_date "${week_ending_date}")"
  snippet_file_path="${snippets_dir}/snippets_${snippet_year}.md"
  snippet_backup_path="${snippet_file_path}.bak"

  #  Make sure that the snippet file exists
  touch "${snippet_file_path}"

  # Check if the weekly snippet exists already. We escape the spaces in the path
  # so that we can copy and paste it.
  grep "${snippet_heading}" "${snippet_file_path}" >/dev/null \
    && fail "It appears the week's snippets are already in the file." \
      "heading: \"${snippet_heading}\", path: \"${snippet_file_path// /\\ }\""

  # Create a temp file for the output
  tmp_file="$(mktemp)"
  cleanup() {
    rm -f "${tmp_file}"
  }
  trap cleanup EXIT

  # Create a new snippet file. Use printf to guarantee a trailing blank
  # line between this entry's `---` separator and the next heading.
  printf '%s\n\n' "${output}" | cat - "${snippet_file_path}" >"${tmp_file}"

  # Backup the curent file
  rm -f "${snippet_backup_path}"
  mv "${snippet_file_path}" "${snippet_backup_path}"

  # Move new file
  mv "${tmp_file}" "${snippet_file_path}"

  # Normalize formatting (line wrap, blank lines, etc.) via prettier. The
  # js_binary launcher requires BAZEL_BINDIR; since we are not running as
  # part of a Bazel action, "." is the documented escape hatch.
  if [[ ${run_prettier} == "true" ]]; then
    BAZEL_BINDIR=. "${prettier_bin}" --print-width 100 --prose-wrap always \
      --write "${snippet_file_path}" >/dev/null
  fi

  echo "Added snippets for the week ending ${week_ending_date} to" \
    "${snippet_file_path// /\\ }."
  if [[ ${launch_vim} == "true" ]]; then
    vim "${snippet_file_path}"
  fi
else
  # Output the markdown to stdout
  echo "${output}"
fi
