# Decision log

One row per decision, newest first. A decision is never erased: when
another replaces it, its status becomes "Replaced by D-nnn" and it moves to
the second table. The owner of the project takes the decisions; the date is
the day they were taken. The reason and the consequences of each one are
in the [project log](project-log.md#decisions-with-their-reasons-and-consequences).

Agents and contributors do not take the owner's decisions: the goal, the
scope, and anything that conflicts with a row of this page. When a task
conflicts with a current decision, they stop and ask the owner. What the
owner left unspecified and the work needs, an agent settles so that the
work keeps moving, and records here with its reason and the status
"Current (assumed, not contested)" until the owner confirms it or replaces
it. Rule 3 of [AGENTS.md](../AGENTS.md) draws the line.

## Current

| Id | Date | Decision | Status |
| --- | --- | --- | --- |
| D-003 | YYYY-MM-DD | Example: what has no meaning on this platform is marked N/A ... | Current |
| D-002 | YYYY-MM-DD | Example: out-of-scope items keep their row and their reason ... | Current |
| D-001 | YYYY-MM-DD | The target is ... | Current |

## Replaced

| Id | Date | Decision | Status |
| --- | --- | --- | --- |
