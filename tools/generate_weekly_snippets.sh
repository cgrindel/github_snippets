#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v2 ---


# MARK - Locate Deps

fail_sh_location=cgrindel_bazel_starlib/shlib/lib/fail.sh
fail_sh="$(rlocation "${fail_sh_location}")" || \
  (echo >&2 "Failed to locate ${fail_sh_location}" && exit 1)
source "${fail_sh}"

github_sh_location=cgrindel_bazel_starlib/shlib/lib/github.sh
github_sh="$(rlocation "${github_sh_location}")" || \
  (echo >&2 "Failed to locate ${github_sh_location}" && exit 1)
source "${github_sh}"

date_sh_location=cgrindel_github_snippets/lib/date.sh
date_sh="$(rlocation "${date_sh_location}")" || \
  (echo >&2 "Failed to locate ${date_sh_location}" && exit 1)
source "${date_sh}"

github_jq_location=cgrindel_github_snippets/lib/jq/github.jq
github_jq="$(rlocation "${github_jq_location}")" || \
  (echo >&2 "Failed to locate ${github_jq_location}" && exit 1)

# MARK - Functions

search_prs() {
  query_args_str="${@}"
  gh api -X GET search/issues -f q="${query_args_str}"
}


# MARK - Process Args

get_usage() {
  local utility="$(basename "${BASH_SOURCE[0]}")"
  echo "$(cat <<-EOF
Generate your weekly snippets using GitHub activity.

Usage:
${utility} 

Options:
EOF
  )"
}

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
    *)
      args+=("${1}")
      shift 1
      ;;
  esac
done


# MARK - Retrieve the closed PRs for the past week.

cd "${BUILD_WORKSPACE_DIRECTORY}"

# Figure out the author
[[ -z "${author:-}" ]] && author="$( get_gh_username )"

# Determine the date range
if [[ -n "${week_with_date:-}" ]]; then
  begin_date="$( find_beginning_of_week "${week_with_date}" )"
else
  begin_date="$( find_beginning_of_previous_week )"
fi
end_date="$( days_after 7 "${begin_date}" )"

# Retrieve the closed PRs
closed_prs_result="$(
  search_prs "type:pr" "state:closed" "author:${author}" \
    "closed:${begin_date}..${end_date}"
)"

# Generate the markdown snippets
jq_lib_dir="$(dirname "${github_jq}")"
snippets="$(
  echo "${closed_prs_result}" | \
    jq -r -L "${jq_lib_dir}" \
      'import "github" as github; github::pr_search_response_to_md '
)"

# Generate the output markdown
week_ending_date="$(days_before 1 "${end_date}")"
snippet_heading="# Week Ending ${week_ending_date}"
output="$(cat <<-EOF
${snippet_heading}

${snippets}

---
  
EOF
)"
# NOTE: If the last line of the here doc above is empty, it will not print the blank line.

# If a snippets directory was provided, then look for the snippet file and update it.
if [[ -n "${snippets_dir:-}" ]]; then
  # Determine the snippet path.
  snippet_year="$( get_year_from_date "${week_ending_date}" )"
  snippet_file_path="${snippets_dir}/snippets_${snippet_year}.md"
  snippet_backup_path="${snippet_file_path}.bak"

  # Create a temp file for the output
  tmp_file="$( mktemp )"
  cleanup() {
    rm -f "${tmp_file}"
  }
  trap cleanup EXIT

  #  Make sure that the snippet file exists
  touch "${snippet_file_path}"

  # Create a new snippet file 
  echo "${output}" | cat - "${snippet_file_path}" > "${tmp_file}"

  # Backup the curent file
  rm -f "${snippet_backup_path}"
  mv "${snippet_file_path}" "${snippet_backup_path}"

  # Move new file
  mv "${tmp_file}" "${snippet_file_path}"
else
  # Output the markdown to stdout
  echo "${output}"
fi

