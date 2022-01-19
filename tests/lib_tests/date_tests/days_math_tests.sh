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

date_sh_location=cgrindel_github_snippets/lib/date.sh
date_sh="$(rlocation "${date_sh_location}")" || \
  (echo >&2 "Failed to locate ${date_sh_location}" && exit 1)
source "${date_sh}"


# MARK - Test days_math

date="2022-01-10"

actual="$( days_math 0 "${date}" )"
assert_equal "2022-01-10" "${actual}" "days_math 0"

actual="$( days_math "-1" "${date}" )"
assert_equal "2022-01-09" "${actual}" "days_math -1"

actual="$( days_math "+1" "${date}" )"
assert_equal "2022-01-11" "${actual}" "days_math +1"


# MARK - Test days_before

date="2022-01-17"

expected_values=("2022-01-17")
expected_values+=("2022-01-16")
expected_values+=("2022-01-15")
expected_values+=("2022-01-14")
expected_values+=("2022-01-13")
expected_values+=("2022-01-12")
expected_values+=("2022-01-11")
expected_values+=("2022-01-10")

for (( i = 0; i < ${#expected_values[@]}; i++ )); do
  expected="${expected_values[$i]}"
  actual="$(days_before "${i}" "${date}")"
  assert_equal "${expected}" "${actual}"
done


# MARK - Test days_after

date="2022-01-10"

actual="$( days_after 0 "${date}" )"
assert_equal "2022-01-10" "${actual}" "days_after 0"

actual="$( days_after "1" "${date}" )"
assert_equal "2022-01-11" "${actual}" "days_after 1"

actual="$( days_after "2" "${date}" )"
assert_equal "2022-01-12" "${actual}" "days_after 2"
