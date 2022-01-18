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

assertions_sh_location=cgrindel_bazel_starlib/shlib/lib/assertions.sh
assertions_sh="$(rlocation "${assertions_sh_location}")" || \
  (echo >&2 "Failed to locate ${assertions_sh_location}" && exit 1)
source "${assertions_sh}"

github_jq_location=cgrindel_github_snippets/lib/jq/github.jq
github_jq="$(rlocation "${github_jq_location}")" || \
  (echo >&2 "Failed to locate ${github_jq_location}" && exit 1)

jq_lib_dir="$(dirname "${github_jq}")"
exec_jq() {
  local jq_script="${1}"
  jq -r -L "${jq_lib_dir}" "${jq_script}" <&0
}

# MARK - Test

actual="$( echo '"  hello  "' | exec_jq 'import "github" as github; github::trim' )"
assert_equal "hello" "${actual}"

fail "IMPLEMENT ME!"
