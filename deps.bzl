"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "c95de004f346cbcb51ba1185e8861227cd9ab248b53046f662aeda1095601bc9",
        strip_prefix = "bazel-starlib-0.7.1",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.7.1.tar.gz",
        ],
    )
