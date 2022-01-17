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

# MARK - Functions

search_prs_for_week() {
  local author="${1}"
  local begin_closed_on="${2:-}"
  local end_closed_on="${3:-}"
  query_args=("state:closed" "type:pr")
  query_args+=("author:${author}")
  [[ -n "${begin_closed_on:-}" ]] && query_args+=("closed:>${begin_closed_on}")
  [[ -n "${end_closed_on:-}" ]] && query_args+=("closed:<${end_closed_on}")
  query_args_str="${query_args[@]}"
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
    *)
      args+=("${1}")
      shift 1
      ;;
  esac
done


# MARK - Retrieve the closed PRs for the past week.

gh_username="$( get_gh_username )"

# DEBUG BEGIN
echo >&2 "*** CHUCK $(basename "${BASH_SOURCE[0]}") gh_username: ${gh_username}" 
# DEBUG END

# closed_prs_result="$(gh api -X GET search/issues -f q="state:closed type:pr author:${gh_username}")"
closed_prs_result="$(search_prs "${gh_username}" "2022-01-10")"

# echo "${closed_prs_result}" | jq '.items | length'
echo "${closed_prs_result}" | jq '.items[0]'
