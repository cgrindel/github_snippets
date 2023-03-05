"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "f0562285a3b18bafed65d09276ce438041f48f0580bb9032a1ce4234724588d0",
        strip_prefix = "bazel-starlib-0.13.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.13.0.tar.gz",
        ],
    )
