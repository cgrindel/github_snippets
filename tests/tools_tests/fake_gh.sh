#!/usr/bin/env bash
#
# Minimal stand-in for `gh`, used by generate_weekly_snippets_test to keep
# the suite hermetic (no network, no auth, no rate limits). It implements
# only the call the generator makes:
#
#   gh api -X GET search/issues -f q=<QUERY>
#
# and returns a canned fixture selected by the qualifiers in <QUERY>.

set -o errexit -o nounset -o pipefail

# Fixtures are co-located with this script. The test exports
# FAKE_GH_FIXTURES_DIR (resolved via runfiles) so this works regardless of
# the runfiles layout; fall back to a path relative to this script.
fixtures_dir="${FAKE_GH_FIXTURES_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"}"

# Extract the search query (the argument beginning with "q=").
query=""
for arg in "$@"; do
  case "${arg}" in
    q=*) query="${arg#q=}" ;;
  esac
done

emit() {
  cat "${fixtures_dir}/${1}"
}

# Match on the distinctive qualifier for each search the generator issues.
case "${query}" in
  *"type:pr"*"reviewed-by:"*) emit reviewed_prs.json ;;
  *"type:pr"*"state:closed"*) emit closed_prs.json ;;
  *"type:issue"*"commenter:"*) emit commented_issues.json ;;
  *"type:issue"*"assignee:"*) emit closed_issues.json ;;
  *"type:issue"*"created:"*) emit opened_issues.json ;;
  *)
    echo >&2 "fake_gh: unrecognized query: ${query}"
    exit 1
    ;;
esac
