# Claude Code Instructions

Use this repository as a guide for developing Ark Survival Ascended AsaApi / ArkServerApi C++ plugins.

This repository is not a server plugin and not a buildable plugin by itself. It is a documentation, template, and checklist project for agents and developers.

## Core Behavior

- Read existing plugin code before making changes.
- Verify every Hook signature, field, wrapper, and native call against the official docs / ASA API Wiki first. Only use the local AsaApi SDK when the Wiki is missing, unclear, likely outdated, or compilation/signatures disagree.
- Separate API facts from engineering advice and project-specific experience.
- Use `rg` for searches.
- Evaluate event Hooks, timers, scans, direct object fields, native calls, and global Hooks by business need, frequency, scope, observability, and rollback path.
- Avoid presenting project-specific incidents or unverified assumptions as general ASA API rules.
- Keep changes scoped and update code, config, tests, docs, and package output together.
- Treat `build/package/<Plugin>/` as a local test directory. It may retain README/changelog copies and local configuration. Only the final external ZIP is distribution-grade: build it from a temporary staging directory or an explicit ZIP whitelist, include only the plugin DLL, `PluginInfo.json`, `config.json`, `config说明.json`, and required runtime files, and exclude developer docs without deleting them from the source tree or local test directory.
- If the server is not local, do not claim server-side validation. Report local build/test/package results and list what must be checked on the server.

## Reference Docs

Read only the docs relevant to the task:

- `docs/api-lookup.md` for official/Wiki-first API and Hook lookup.
- `docs/development-workflow.md` for implementation flow.
- `docs/official-api-sources.md` for source boundaries.
- `docs/stability.md` for risk boundaries.
- `docs/config-and-commands.md` for config and command conventions.
- `docs/messaging.md` for player-facing messages.
- `docs/debugging.md` for crash/no-response diagnosis.
- `docs/build-test-package.md` for build and packaging.
- `docs/release-checklist.md` before delivering a release package.

## Output Expectations

When finishing plugin work, report:

- What changed.
- What was built or tested.
- Package path.
- DLL timestamp when relevant.
- Any server-side verification still required.

Keep user-facing explanations concise and practical.
