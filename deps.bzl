"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "81b69a0ba4eb7352189973ee283cce751c07c25a71e5eb707455b80437cd6c42",
        strip_prefix = "bazel-starlib-0.14.9",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.14.9.tar.gz",
        ],
    )
