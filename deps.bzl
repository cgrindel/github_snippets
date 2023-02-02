"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "c4d63dc38d6bbd0af2bf8e8bb3af5626c81d19e23d134bf87c85e16e4fa9adba",
        strip_prefix = "bazel-starlib-0.12.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.12.0.tar.gz",
        ],
    )
