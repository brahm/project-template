# Lessons

What went wrong in {{PROJECT_NAME}}, and the guard that now prevents it.
The rules of [AGENTS.md](../AGENTS.md) were born this way: a complication
or a failure that the owner caught became a rule. This page keeps that
going without the owner having to write the rule.

A row is added when the owner corrects an agent or has to repeat an
instruction, when a check or a review catches what a rule should have
prevented, when the same mistake happens twice, or when work is redone
because something was not specified.

## The register

| Id | Date | What went wrong | Cause | Guard | Status |
| --- | --- | --- | --- | --- | --- |
| L-001 | YYYY-MM-DD | Example: an item was called done without being compared with its reference | The check was by eye and was not recorded | Rule 14 of AGENTS.md and the `review` column of the inventory | guarded |

| Column | Meaning |
| --- | --- |
| `Id` | `L-` and a number of at least three digits, never reused |
| `What went wrong` | The event, in one sentence, without blame |
| `Cause` | Why it could happen: no rule, an unclear rule, a rule nobody applied, something not specified |
| `Guard` | What now prevents it, and where: the check, the skill, the rule or the page |
| `Status` | `open` (no guard yet), `guarded` (the guard is in this project), `proposed` (worth taking to the template), or `in template` with the pull request that took it there |

## Choosing the guard

Take the first of these that would have caught the problem:

1. **A check** in `scripts/` that `scripts/check-all.sh` and the CI run.
   It costs nothing when it passes, and it cannot be forgotten.
2. **A line in the skill** that runs at that moment.
3. **A sharper wording** of a rule that already exists in AGENTS.md.
4. **A new rule** in AGENTS.md, only when none of the others can do it.

A default of design or of code goes in [engineering.md](engineering.md).
AGENTS.md is read at the start of every session, so it stays short: when
a rule needs detail, the detail goes to a page of `docs` or to a skill.

## Taking a lesson to the template

A lesson that would help any project, not only this one, gets the status
`proposed`, and the owner is told. The `update-from-template` skill says
how it travels to the template this project was made from
([kit.md](kit.md)).
