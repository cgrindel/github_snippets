"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "64bc67b2a513926f0605e93d17bcfcb65daf852bed5d5d913f29c30a9ab377a8",
        strip_prefix = "bazel-starlib-0.14.3",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.14.3.tar.gz",
        ],
    )
