"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "df971d4736cf30ab5332536715eeb00c1a67ca6440610e8bc3b73a35aaff34dc",
        strip_prefix = "bazel-starlib-0.16.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.16.0.tar.gz",
        ],
    )
