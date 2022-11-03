"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "116bfd53999992c21b758a9854af29dfd77470f8d9f919be81e2034f003a5b31",
        strip_prefix = "bazel-starlib-999.0.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v999.0.0.tar.gz",
        ],
    )
