# Using this template

This repository is a starting point for a project developed by an owner
who decides and approves, with coding agents that plan, write and document.
It carries the rules (`AGENTS.md`), the documents they rely on (`docs/`),
twelve skills (`.claude/skills/`), a Second Brain of notes (`docs/brain/`), a backlog register, a progress dashboard
generated from the repository, and checks that keep them honest.

1. Create the new repository from this one (GitHub: "Use this template"),
   or copy the folder.
2. Open your coding agent in it and say what you want to build.

That is all. The agent sees that the project has not been started
(`AGENTS.md` says so, and `scripts/status.py` prints it when a Claude Code
session starts) and follows the `start-project` skill by itself: it runs
`./init-project.sh` to fill the placeholders, asks only what blocks the
plan, writes the goals, the decisions, the inventory and the roadmap, fits
the rules, the skills and the checks to your technology, and reports what
it assumed. You never have to name a skill.

To do the first step by hand instead, run `./init-project.sh` at the root.
It asks for the name, the owner, the languages, the time zone and the
licence, fills the placeholders, gives each agent its pointer to
`AGENTS.md` and its skills, and deletes itself and this file.

Every placeholder looks like `{{NAME}}`; `grep -rnE '\{\{[A-Z_]+\}\}' .` lists
any left (the `${{ ... }}` of the GitHub workflows are not placeholders),
and `scripts/check-docs.py` fails while one remains.
