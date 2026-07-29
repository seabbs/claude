---
name: julia-repl
description: Evaluate Julia through the warm AgentREPL MCP session rather than `julia -e`, hot-reload edits with Revise, and filter TestItemRunner suites while iterating. Use for any Julia evaluation, package iteration, or test run, and to decide when a fresh process is needed instead.
---

# Julia REPL over MCP

The `mcp__julia-repl__*` tools drive a Julia process that stays alive for the
whole session, so startup and compilation cost is paid once rather than on every
`julia -e`.
`dotfiles/claude/settings.json` starts the server and
`dotfiles/julia/setup-packages.jl` installs it into the `@AgentREPL` shared
environment.

## Invoking it

| Tool | Use |
|---|---|
| `eval` | run code (`code`) |
| `revise` | reload edited files (`action="revise"`) |
| `info` | Julia version, active project, worker pid, user variables |
| `activate` | switch project (`path`), then `pkg` `action="instantiate"` |
| `pkg` | `add`, `rm`, `status`, `update`, `test`, `develop` |
| `session` | isolated named sessions (`action`, `name`) |
| `reset` | kill the worker and spawn a clean one |

The server activates the session's working directory on startup, so in a package
repo the package is already the active project.
`log_viewer` opens a terminal in the human's tmux, so ask before calling it.

## Hot or cold

Iterate hot, verify cold.

Reach for a fresh process, either `reset` or plain `julia --project=.` in Bash,
when:

- verifying anything before a commit, so no result rests on session state
- measuring startup, TTFX, or precompilation
- a reload leaves behaviour that no longer makes sense

Everything else belongs in the warm session.

## Revise

Call `revise` with `action="revise"` after editing a `.jl` file, then re-eval.
Method changes reload, and on Julia 1.12 struct and const changes reload too,
verified here with Revise 3.16 and the `revise_structs` preference that
`setup-packages.jl` sets.
`reset` remains the fix when a reload leaves the session inconsistent.
A script outside a package needs `revise` with `action="includet"` once.

## Tests

Narrow the filter while iterating, then run the full suite in a fresh process
before finishing.

```julia
@run_package_tests filter = ti -> contains(ti.filename, "growth")
@run_package_tests filter = ti -> ti.name == "growth rate stays positive"
@run_package_tests filter = ti -> :integration in ti.tags
```

`pkg` with `action="test"` is the cold run, since `Pkg.test` starts its own
process.

## One worker per client

The server speaks STDIO and spawns a private worker per client, so Claude Code,
pi and Neovim each get their own session and cannot share one.
The human tmux and vim-slime REPL is separate again, and stays that way.

Each client costs about 1 GB resident before any package loads (measured: 581 MB
server plus 428 MB worker), so on a shared host drop sessions you no longer need
with `session` `action="destroy"`.
