# Using this template

This repository is a starting point for a project developed by an owner
who decides and approves, with coding agents that plan, write and document.
It carries the rules (`AGENTS.md`), the documents they rely on (`docs/`),
eight skills (`.claude/skills/`), a backlog register, a progress dashboard
generated from the repository, and CI that checks them.

1. Create the new repository from this one (GitHub: "Use this template"),
   or copy the folder.
2. Run `./init-project.sh` at its root. It asks for the name, the owner,
   the languages, the time zone and the licence, fills the placeholders,
   gives each agent its pointer to `AGENTS.md` and its skills, and deletes
   itself and this file.
3. Ask your agent to run the `start-project` skill with your brief, or
   fill the pages of `docs/` by hand.

Every placeholder looks like `{{NAME}}`; `grep -rnE '\{\{[A-Z_]+\}\}' .` lists
any left (the `${{ ... }}` of the GitHub workflows are not placeholders).
