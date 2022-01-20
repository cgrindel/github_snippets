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

assertions_sh_location=cgrindel_bazel_starlib/shlib/lib/assertions.sh
assertions_sh="$(rlocation "${assertions_sh_location}")" || \
  (echo >&2 "Failed to locate ${assertions_sh_location}" && exit 1)
source "${assertions_sh}"

generate_weekly_snippets_sh_location=cgrindel_github_snippets/tools/generate_weekly_snippets.sh
generate_weekly_snippets_sh="$(rlocation "${generate_weekly_snippets_sh_location}")" || \
  (echo >&2 "Failed to locate ${generate_weekly_snippets_sh_location}" && exit 1)


# MARK - Set Up Git Repo

# Clone this repo so that we have an actual git repository for the test
repo_dir="${PWD}/repo"
rm -rf "${repo_dir}"
repo_url="https://github.com/cgrindel/github_snippets"
git clone "${repo_url}" "${repo_dir}" 2>/dev/null

# Any utilities under test need to know where the workspace directory is. In
# this case, we are faking it out by setting it to our cloned repo directory.
export "BUILD_WORKSPACE_DIRECTORY=${repo_dir}"


# MARK - Test Using Defaults

output="$( "${generate_weekly_snippets_sh}" --author cgrindel )"
assert_match "# Week Ending" "${output}"


# MARK - Test Specifying Date for a Specific Week

# 2022-01-05 is a Wed. This command should generate snippets for the week
# ending 2022-01-09 (Sun) which is a search range of 2022-01-02 to 2022-01-10.
output="$( 
  "${generate_weekly_snippets_sh}" \
    --author cgrindel \
    --week_with_date "2022-01-05" 
)"
assert_match "# Week Ending 2022-01-09" "${output}"
assert_match "https://github.com/cgrindel/bazel-doc/pull/15" "${output}"
assert_match "https://github.com/cgrindel/gha_select_value/pull/2" "${output}"


# MARK - Test Creating a New Snippet File

snippets_dir="${PWD}/snippets"
rm -rf "${snippets_dir}"
mkdir -p "${snippets_dir}"

"${generate_weekly_snippets_sh}" \
  --author cgrindel \
  --week_with_date "2022-01-05" \
  --snippets_dir "${snippets_dir}"

expected_snippets_file="${snippets_dir}/snippets_2022.md"
[[ -e "${expected_snippets_file}" ]] || \
  fail "Expected snippets file to be created. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-09" > /dev/null) || \
  fail "Expected to find snippets in created snippet file. ${expected_snippets_file}"


# MARK - Test Updating An Existing Snippet File

"${generate_weekly_snippets_sh}" \
  --author cgrindel \
  --week_with_date "2022-01-12" \
  --snippets_dir "${snippets_dir}"

[[ -e "${expected_snippets_file}" ]] || \
  fail "Expected snippets file to after update. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-16" > /dev/null) || \
  fail "Expected to find new snippet in updated snippet file. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-09" > /dev/null) || \
  fail "Expected to find old snippet in updated snippet file. ${expected_snippets_file}"
