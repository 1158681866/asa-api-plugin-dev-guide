# Claude Code Instructions

Use this repository as a guide for developing Ark Survival Ascended AsaApi / ArkServerApi C++ plugins.

This repository is not a server plugin and not a buildable plugin by itself. It is a documentation, template, and checklist project for agents and developers.

## Core Behavior

- Read existing plugin code before making changes.
- Verify every Hook signature, field, wrapper, and native call against the local AsaApi SDK or existing project code.
- Use `rg` for searches.
- Prefer event-driven Hooks and objects passed directly by Hook parameters.
- Avoid unbounded scans, high-frequency global Hooks, noisy logs, and broad script-dispatch Hooks unless explicitly justified.
- Keep changes scoped and update code, config, tests, docs, and package output together.
- If the server is not local, do not claim server-side validation. Report local build/test/package results and list what must be checked on the server.

## Reference Docs

Read only the docs relevant to the task:

- `docs/api-lookup.md` for SDK and Hook lookup.
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
