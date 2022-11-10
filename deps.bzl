"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "3a3b3a5e9b0f63e8a9a193a66bc588c1f2fb2873562be68f2026adb815eea06f",
        strip_prefix = "bazel-starlib-0.8.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.8.0.tar.gz",
        ],
    )
