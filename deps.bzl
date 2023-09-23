"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "ad9ff755a96f8f88de099a2bf673e6fb84077adbad243e286c4ae9549e760ebf",
        strip_prefix = "bazel-starlib-0.18.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.18.0.tar.gz",
        ],
    )
