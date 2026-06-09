#!/usr/bin/env bash

# --- begin runfiles.bash initialization v2 ---
# Copy-pasted from the Bazel Bash runfiles library v2.
set -uo pipefail
f=bazel_tools/tools/bash/runfiles/runfiles.bash
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

assertions_sh_location=cgrindel_bazel_starlib/shlib/lib/assertions.sh
assertions_sh="$(rlocation "${assertions_sh_location}")" \
  || (echo >&2 "Failed to locate ${assertions_sh_location}" && exit 1)
source "${assertions_sh}"

generate_weekly_snippets_sh_location=cgrindel_github_snippets/tools/generate_weekly_snippets.sh
generate_weekly_snippets_sh="$(rlocation "${generate_weekly_snippets_sh_location}")" \
  || (echo >&2 "Failed to locate ${generate_weekly_snippets_sh_location}" && exit 1)

# MARK - Hermetic gh

# Inject a fake gh so the test never touches the network, GitHub auth, or
# rate limits. The generator picks it up via the GH_BIN seam, and the fake
# returns canned fixtures keyed off the search qualifiers.
fake_gh_location=cgrindel_github_snippets/tests/tools_tests/fake_gh.sh
fake_gh="$(rlocation "${fake_gh_location}")" \
  || (echo >&2 "Failed to locate ${fake_gh_location}" && exit 1)
export GH_BIN="${fake_gh}"

# Resolve the fixtures directory through runfiles and hand it to the fake so
# it works regardless of the runfiles layout.
a_fixture_location=cgrindel_github_snippets/tests/tools_tests/fixtures/closed_prs.json
a_fixture="$(rlocation "${a_fixture_location}")" \
  || (echo >&2 "Failed to locate ${a_fixture_location}" && exit 1)
export FAKE_GH_FIXTURES_DIR="$(dirname "${a_fixture}")"

# MARK - Fake Workspace

# The generator cd's into BUILD_WORKSPACE_DIRECTORY and writes snippet files
# there. It performs no git operations, so a plain directory suffices.
repo_dir="${PWD}/workspace"
rm -rf "${repo_dir}"
mkdir -p "${repo_dir}"
export "BUILD_WORKSPACE_DIRECTORY=${repo_dir}"

# MARK - Test Using Defaults

output="$("${generate_weekly_snippets_sh}" --no_summary --author cgrindel)"
assert_match "# Week Ending" "${output}"

# MARK - Test Specifying Date for a Specific Week

# 2022-01-05 is a Wed. This command should generate snippets for the week
# ending 2022-01-09 (Sun) which is a search range of 2022-01-02 to 2022-01-10.
output="$(
  "${generate_weekly_snippets_sh}" \
    --no_summary \
    --author cgrindel \
    --week_with_date "2022-01-05"
)"
assert_match "# Week Ending 2022-01-09" "${output}"

# Every activity section is rendered, with the content from its fixture.
assert_match "### Authored" "${output}"
assert_match "https://github.com/cgrindel/example/pull/101" "${output}"
assert_match "### Reviewed" "${output}"
assert_match "https://github.com/cgrindel/example/pull/102" "${output}"
assert_match "### Issues Opened" "${output}"
assert_match "https://github.com/cgrindel/example/issues/201" "${output}"
assert_match "### Issues Closed" "${output}"
assert_match "https://github.com/cgrindel/example/issues/202" "${output}"
assert_match "### Issues Commented" "${output}"
assert_match "https://github.com/cgrindel/example/issues/203" "${output}"

# MARK - Test Creating a New Snippet File

snippets_dir="${PWD}/snippets"
rm -rf "${snippets_dir}"
mkdir -p "${snippets_dir}"

"${generate_weekly_snippets_sh}" \
  --no_launch_vim \
  --no_summary \
  --author cgrindel \
  --week_with_date "2022-01-05" \
  --snippets_dir "${snippets_dir}"

expected_snippets_file="${snippets_dir}/snippets_2022.md"
[[ -e ${expected_snippets_file} ]] \
  || fail "Expected snippets file to be created. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-09" >/dev/null) \
  || fail "Expected to find snippets in created snippet file. ${expected_snippets_file}"

# Sanity-check that prettier ran: it normalizes by inserting a blank line
# between '### Authored' and the first repo bullet (the generator emits
# them with no blank line). This catches breakage in the prettier
# toolchain wiring (e.g. after a Renovate bump of rules_js / rules_lint /
# prettier itself) that would otherwise pass the other assertions.
awk '
  /^### Authored$/ {
    getline next_line
    if (next_line == "") { found = 1 }
  }
  END { exit !found }
' "${expected_snippets_file}" \
  || fail "Expected prettier to insert a blank line after '### Authored' in ${expected_snippets_file}"

# MARK - Test Updating An Existing Snippet File

"${generate_weekly_snippets_sh}" \
  --no_launch_vim \
  --no_summary \
  --author cgrindel \
  --week_with_date "2022-01-12" \
  --snippets_dir "${snippets_dir}"

[[ -e ${expected_snippets_file} ]] \
  || fail "Expected snippets file to after update. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-16" >/dev/null) \
  || fail "Expected to find new snippet in updated snippet file. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-09" >/dev/null) \
  || fail "Expected to find old snippet in updated snippet file. ${expected_snippets_file}"

# MARK - Test Fail if Adding Snippets for Existing Week

"${generate_weekly_snippets_sh}" \
  --no_launch_vim \
  --no_summary \
  --author cgrindel \
  --week_with_date "2022-01-12" \
  --snippets_dir "${snippets_dir}" || echo "Expected failure occurred."

[[ -e ${expected_snippets_file} ]] \
  || fail "Expected snippets file to exist after failed update. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-16" >/dev/null) \
  || fail "Expected to find second snippet after failed update. ${expected_snippets_file}"
(cat "${expected_snippets_file}" | grep "# Week Ending 2022-01-09" >/dev/null) \
  || fail "Expected to find first snippet after failed update. ${expected_snippets_file}"

# MARK - Test --no_format Skips Prettier

raw_snippets_dir="${PWD}/raw_snippets"
rm -rf "${raw_snippets_dir}"
mkdir -p "${raw_snippets_dir}"

"${generate_weekly_snippets_sh}" \
  --no_launch_vim \
  --no_summary \
  --no_format \
  --author cgrindel \
  --week_with_date "2022-01-05" \
  --snippets_dir "${raw_snippets_dir}"

raw_snippets_file="${raw_snippets_dir}/snippets_2022.md"
[[ -e ${raw_snippets_file} ]] \
  || fail "Expected raw snippets file to be created. ${raw_snippets_file}"

# Inverse of the assertion above: with --no_format, prettier is skipped,
# so the line right after '### Authored' should be the first repo bullet
# (no blank line in between).
awk '
  /^### Authored$/ {
    getline next_line
    if (next_line == "") { found_blank = 1 }
  }
  END { exit found_blank }
' "${raw_snippets_file}" \
  || fail "Expected NO blank line after '### Authored' under --no_format in ${raw_snippets_file}"
