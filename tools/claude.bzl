"""Helper rule that surfaces the rules_claude runtime toolchain's binary as
a runfile and as a make variable for sh_binary consumption.

rules_claude ships the toolchain types and the `claude_run`/`claude_test`
rules, but does not include a generic "resolved toolchain" target that an
sh_binary can depend on. This rule fills that gap: list it in both the
sh_binary's `data` (so the binary lands in runfiles) and `toolchains` (so
`$(CLAUDE_BIN)` expands in the `env` attribute).
"""

load(
    "@rules_claude//claude:defs.bzl",
    "CLAUDE_RUNTIME_TOOLCHAIN_TYPE",
)

def _claude_runfile_impl(ctx):
    toolchain = ctx.toolchains[CLAUDE_RUNTIME_TOOLCHAIN_TYPE]
    binary = toolchain.claude_info.binary
    return [
        DefaultInfo(
            files = depset([binary]),
            runfiles = ctx.runfiles(files = [binary]),
        ),
        platform_common.TemplateVariableInfo({
            "CLAUDE_BIN": binary.path,
        }),
    ]

claude_runfile = rule(
    implementation = _claude_runfile_impl,
    toolchains = [CLAUDE_RUNTIME_TOOLCHAIN_TYPE],
)
