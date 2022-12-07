"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "99132d1074717e3952ebe57e9bddcd76e735bc83336093d8dc6a0820e6819998",
        strip_prefix = "bazel-starlib-0.10.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.10.0.tar.gz",
        ],
    )
