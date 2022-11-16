"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "f10f9a47f23a76e6cc6f8af0b2d0c6377452e5b17ebeed6dbd656f0ba2aaa4ec",
        strip_prefix = "bazel-starlib-0.8.1",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.8.1.tar.gz",
        ],
    )
