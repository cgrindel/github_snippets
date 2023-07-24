"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "695984d03d438052a637b7c1958c85bd076396257b60cc098ee36612867c1436",
        strip_prefix = "bazel-starlib-0.16.2",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.16.2.tar.gz",
        ],
    )
