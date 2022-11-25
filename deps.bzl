"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "42a496dddbc089c68cd72b1f20dfe6acf474c53043dafe230ec887f617c0c252",
        strip_prefix = "bazel-starlib-0.9.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.9.0.tar.gz",
        ],
    )
