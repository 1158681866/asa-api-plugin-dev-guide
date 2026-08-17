# Claude Code Adapter

This file is an optional discovery adapter, not a separate rule set.

Read and follow [`skills/asa-api-plugin-dev/SKILL.md`](skills/asa-api-plugin-dev/SKILL.md). Resolve every `references/...` path relative to that skill directory and load only the references needed for the current task.

If the skill bundle is not present at that path, install or locate the complete `asa-api-plugin-dev` skill instead of treating this file as a standalone guide. The canonical rules live only in `skills/asa-api-plugin-dev/`.
