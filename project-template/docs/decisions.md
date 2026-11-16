# Decision log

One row per decision, newest first. A decision is never erased: when
another replaces it, its status becomes "Replaced by D-nnn" and it moves to
the second table. The owner of the project takes the decisions; the date is
the day they were taken. The reason and the consequences of each one are
in the [project log](project-log.md#decisions-with-their-reasons-and-consequences).

Agents and contributors do not take decisions. When a task conflicts with a
current decision, they stop and ask the owner. A decision that an agent
had to assume to keep working is recorded with the status
"Current (assumed, not contested)" until the owner confirms it.

## Current

| Id | Date | Decision | Status |
| --- | --- | --- | --- |
| D-001 | YYYY-MM-DD | The target is ... | Current |

## Replaced

| Id | Date | Decision | Status |
| --- | --- | --- | --- |
