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


# MARK - Test

# Arizona (MST) has no DST, so the offset is always UTC-7.
actual="$(TZ=America/Phoenix local_midnight_to_utc_ts "2026-11-09")"
assert_equal "2026-11-09T07:00:00.000" "${actual}" "Phoenix"

# Los Angeles is UTC-7 in summer (PDT) and UTC-8 in winter (PST).
actual="$(TZ=America/Los_Angeles local_midnight_to_utc_ts "2026-07-06")"
assert_equal "2026-07-06T07:00:00.000" "${actual}" "Los Angeles PDT"
actual="$(TZ=America/Los_Angeles local_midnight_to_utc_ts "2026-11-09")"
assert_equal "2026-11-09T08:00:00.000" "${actual}" "Los Angeles PST"

actual="$(TZ=UTC local_midnight_to_utc_ts "2026-11-09")"
assert_equal "2026-11-09T00:00:00.000" "${actual}" "UTC"
