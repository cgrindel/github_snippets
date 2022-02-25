"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "8ac3e45dc237121283d70506497ec39feb5092af9a57bfe34f7abf4a6bd2ebaa",
        strip_prefix = "bazel-starlib-0.6.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.6.0.tar.gz",
        ],
    )
