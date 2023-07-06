"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "888483f8e8e481bcd3a601b7d5d6641bd62782fd6b6700a91a6603f8c8aba257",
        strip_prefix = "bazel-starlib-0.16.1",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.16.1.tar.gz",
        ],
    )
