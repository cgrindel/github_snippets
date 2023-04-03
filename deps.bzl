"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "db973c439a2ffb4e99a76f74b245bec5c25a2c5ee51a088f56a315e4dc9fa84a",
        strip_prefix = "bazel-starlib-0.15.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.15.0.tar.gz",
        ],
    )
