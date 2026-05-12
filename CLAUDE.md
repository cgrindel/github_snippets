# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A Bazel-built tool that generates weekly status "snippets" by querying
GitHub for the user's closed and reviewed PRs over a given week and
emitting a Markdown summary, optionally prepending it to a yearly
`snippets_YYYY.md` file.

The primary entry point is the `//tools:generate_weekly_snippets`
`sh_binary` target.

## Build & test

This is a Bazel module (`bzlmod`, no `WORKSPACE` content). The pinned
Bazel version lives in `.bazelversion`; invoke via `bazel` or
`bazelisk`.

```bash
# Run the snippet generator (BUILD_WORKSPACE_DIRECTORY is set by `bazel run`)
bazel run //tools:generate_weekly_snippets -- --help

# Build everything
bazel build //...

# Run the full test suite (some tests need gh auth — see below)
bazel test //...

# Run a single test target
bazel test //tests/lib_tests/date_tests:days_math_tests
bazel test //tests/tools_tests:generate_weekly_snippets_test

# Bazel-file formatting maintenance
bazel run //:bzlformat_missing_pkgs_fix     # add bzlformat_pkg to new packages
bazel run //:bzlformat_missing_pkgs_test    # CI check: every package has it
bazel run //:update_all                     # run all updatesrc fixers
```

The `//tests/tools_tests:generate_weekly_snippets_test` test calls
GitHub's API through `gh`, so it needs `GH_TOKEN` or `GITHUB_TOKEN` in
the environment (or a working `gh auth status`). Those vars are passed
through via `env_inherit` in its `BUILD.bazel`.

## Architecture

Three layers, top-down:

1. **`tools/generate_weekly_snippets.sh`** — the orchestrator. Locates
   its dependencies via Bazel runfiles (`rlocation`), computes the week
   boundaries, issues two `gh api search/issues` calls (closed-by-author
   and reviewed-by-author), pipes each JSON response through `jq` with
   the project's `github` module, and either prints the Markdown or
   prepends it to `snippets_<year>.md` in a `--snippets_dir`.

2. **`lib/date.sh`** — BSD `date` wrappers (`-ju -v…`). This is why CI
   runs on `macos-15`: the date math is not portable to GNU `date`.
   Anything date-related goes through `do_date_cmd`, `days_math`,
   `find_beginning_of_week`, etc.

3. **`lib/jq/github.jq`** — `jq` module with the rendering logic. The
   `repo_title` function holds a hard-coded map from `org/repo` to a
   friendly display title; add new repos there when adopting them.
   `format_pr_body` strips `Closes #N` / `Resolves #N` / `Related to #N`
   noise lines.

External `gh` and `jq` binaries are vendored through Bazel — `gh` via
`rules_multitool` (see `multitool.lock.json`), `jq` via the `jq.bzl`
toolchain (the binary path is plumbed through the `JQ_BIN` env var and
the `@jq_toolchains//:resolved_toolchain` toolchain). Do not assume a
system `gh`/`jq`; always resolve through runfiles inside scripts.

## Conventions specific to this repo

- Every Bazel package gets a `bzlformat_pkg(name = "bzlformat")` target
  — `//:bzlformat_missing_pkgs_test` enforces it in CI. When adding a
  new package, run `bazel run //:bzlformat_missing_pkgs_fix`.
- Shell tests use `cgrindel_bazel_starlib`'s `shlib/lib:assertions` and
  the standard Bazel `runfiles.bash` v2 bootstrap. Copy the pattern
  from an existing test (e.g. `tests/lib_tests/date_tests/`).
- CI is macOS-only; do not introduce GNU-date-only constructs in
  `lib/date.sh`.
