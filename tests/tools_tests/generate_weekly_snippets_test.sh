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


# MARK - Test

output="$( "${generate_weekly_snippets_sh}" )"
assert_match "# Week Ending" "${output}"

