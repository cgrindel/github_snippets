load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def github_snippets_dependencies():
    maybe(
        http_archive,
        name = "cgrindel_bazel_starlib",
        sha256 = "9e054e423bb7674e02052e52725b41288369dd94efff963479f76fe269b5177f",
        strip_prefix = "bazel-starlib-0.3.1",
        urls = [
            "http://github.com/cgrindel/bazel-starlib/archive/v0.3.1.tar.gz",
        ],
    )
