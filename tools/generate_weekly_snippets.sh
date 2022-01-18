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

pr_search_result_to_md_jq_location=cgrindel_github_snippets/tools/pr_search_result_to_md.jq
pr_search_result_to_md_jq="$(rlocation "${pr_search_result_to_md_jq_location}")" || \
  (echo >&2 "Failed to locate ${pr_search_result_to_md_jq_location}" && exit 1)

# MARK - Functions

search_prs() {
  query_args_str="${@}"
  gh api -X GET search/issues -f q="${query_args_str}"
}

# pr_to_md() {
#   local pr_json="${1}"
#   echo "${pr_json}"
#   # echo "${pr_json}" | jq -r '
# # "- [\(.title)](\(.html_url))"
# # '
# }
# # Need to export the function so that we can use it with xargs later.
# export -f pr_to_md

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
    *)
      args+=("${1}")
      shift 1
      ;;
  esac
done

# [[ ${#args[@]} > 0 ]] && target_date="${args[0]}"

cd "${BUILD_WORKSPACE_DIRECTORY}"

# MARK - Retrieve the closed PRs for the past week.

gh_username="$( get_gh_username )"

begin_date="$( find_beginning_of_previous_week )"
end_date="$( days_after 7 "${begin_date}" )"
closed_prs_result="$(
  search_prs "type:pr" "state:closed" "author:${gh_username}" \
    "closed:${begin_date}..${end_date}"
)"

# DEBUG BEGIN
# echo "${closed_prs_result}" | jq -r '"Total Count: \(.total_count)"'
# echo "${closed_prs_result}" | jq '.total_count'
# echo "${closed_prs_result}" | jq '.items | length'
# # echo "${closed_prs_result}" | jq '.items[0]'
echo "${closed_prs_result}" | jq '.items[0]'
# DEBUG END

echo "${closed_prs_result}" | jq -r -f "${pr_search_result_to_md_jq}"
