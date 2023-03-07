"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "8b762188a2788684fedf3bcee115bc243a2f9173a6cee7d73a645c90e843d63c",
        strip_prefix = "bazel-starlib-0.13.1",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.13.1.tar.gz",
        ],
    )
