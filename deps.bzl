"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "00c5a281d5b9af70aeefb599d9daa77ea87c5f81c7233dcddd2934e3b641ab2c",
        strip_prefix = "bazel-starlib-0.17.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.17.0.tar.gz",
        ],
    )
