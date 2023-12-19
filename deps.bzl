"""Dependencies for github_snippets."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "fa62fc83374722e47ad4ea7acfa3cf40d59231a167218bbade11963dde1acee0",
        strip_prefix = "bazel-starlib-0.19.0",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.19.0.tar.gz",
        ],
    )
