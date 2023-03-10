"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "f455ef4bc39790957c6ce970e3ad829304294ba2ebf218f37c9947d5939c0bc3",
        strip_prefix = "bazel-starlib-0.14.4",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.14.4.tar.gz",
        ],
    )
