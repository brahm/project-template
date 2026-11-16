# Claude

The rules of this project are in [AGENTS.md](AGENTS.md), the single source
shared by every coding agent. Read it first and follow it.

@AGENTS.md

The project's skills are in `.claude/skills/`. Use them at the moments
AGENTS.md describes: `plan-task-set` before starting, `defer-work` when
something is left undone, `record-decision` when the owner decides,
`validate-against-reference` before calling behaviour done, and
`close-task-set` (or `close-phase`) at the end.
