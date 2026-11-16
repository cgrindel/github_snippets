#!/usr/bin/env bash
#
# Minimal stand-in for `curl`, used by generate_weekly_snippets_test to keep
# the EARLY calls hermetic. It implements only the calls the generator
# makes:
#
#   curl ... --config - -X POST <base>/developer/sign-in
#   curl ... --config - <base>/folders
#   curl ... --config - <base>/time-entries/<start>/<end>
#
# and returns a canned fixture selected by the URL. Each URL is appended to
# FAKE_CURL_LOG when set. FAKE_CURL_FAIL=1 makes every call fail.

set -o errexit -o nounset -o pipefail

fixtures_dir="${FAKE_GH_FIXTURES_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)"}"

# The generator passes headers and the body as curl config on stdin.
config="$(cat)"

url=""
for arg in "${@}"; do
  case "${arg}" in
    http*) url="${arg}" ;;
  esac
done

[[ -n ${FAKE_CURL_LOG:-} ]] && echo "${url}" >>"${FAKE_CURL_LOG}"

if [[ ${FAKE_CURL_FAIL:-} == "1" ]]; then
  echo >&2 "fake_curl: simulated failure for ${url}"
  exit 22
fi

require_auth() {
  if [[ ${config} != *"Authorization: Bearer fake-token"* ]]; then
    echo >&2 "fake_curl: missing bearer token for ${url}"
    exit 22
  fi
}

case "${url}" in
  */developer/sign-in)
    if [[ ${config} != *'apiKey'*'fake-key'* ]]; then
      echo >&2 "fake_curl: sign-in body missing API key"
      exit 22
    fi
    cat "${fixtures_dir}/early_sign_in.json"
    ;;
  */folders)
    require_auth
    cat "${fixtures_dir}/early_folders.json"
    ;;
  */time-entries/*)
    require_auth
    cat "${fixtures_dir}/early_time_entries.json"
    ;;
  *)
    echo >&2 "fake_curl: unrecognized URL: ${url}"
    exit 22
    ;;
esac
