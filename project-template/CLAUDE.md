# Claude

The rules of this project are in [AGENTS.md](AGENTS.md), the single source
shared by every coding agent. Read it first and follow it.

@AGENTS.md

`.claude/settings.json` runs `scripts/status.py` when a session starts, so
the state of the project is already in your context, and allows the
project's own check scripts to run without asking. The skills of
`.claude/skills/` apply at the moments rule 2 of AGENTS.md names; the
owner does not invoke them.
