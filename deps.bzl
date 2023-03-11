"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "025cd876c72a78497033f4595a59f254c21e31ae5184384f9bf5d30c802e6805",
        strip_prefix = "bazel-starlib-0.14.8",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.14.8.tar.gz",
        ],
    )
