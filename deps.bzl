"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "aeaaad85abce703bf1ab85af49312132cd31c22b1d3a7f86799a0f42021dfb29",
        strip_prefix = "bazel-starlib-0.18.1",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.18.1.tar.gz",
        ],
    )
