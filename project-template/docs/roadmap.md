# Roadmap

The implementation plan for the target of [goals.md](goals.md), written on
YYYY-MM-DD. The `phase` column of the [inventory](inventory/README.md)
gives every item its phase.

## How a phase runs

1. **Start:** list the inventory rows of the phase and, for each, how it
   will be checked ([verification.md](verification.md)). Order them: what
   unblocks other work first, then what the owner asked for first, then
   what carries most risk. Set the phase to `in-progress` in
   [`dashboard/phases.tsv`](dashboard/phases.tsv).
2. **Work:** each item comes with tests, comments by the standard of
   [CONTRIBUTING.md](../CONTRIBUTING.md), and its inventory row updated.
3. **Anything left undone** gets a row in
   [`backlog/deferred.tsv`](backlog/README.md) in the same pull request,
   and the owner is told which item moved to which phase.
4. **End:** the backlog of the phase is worked, then
   `scripts/check-backlog.py --phase NAME` and `scripts/check-all.sh` pass.
   A row that still cannot be done moves to a named later phase, with the
   owner told. The phase is set to `done`, and its estimate is corrected
   here and in [`dashboard/forecast.tsv`](dashboard/forecast.tsv).

## Phases

The dashboard reads this table: keep its form, one row per phase, the id in
bold at the start of the first cell, the number of inventory rows (or `-`)
and the estimate in days (or text, such as "In progress").

| Phase | What it delivers | Inventory rows | Estimate (days) |
| --- | --- | --- | --- |
| **P0** Planning | Goals, decisions, inventory, architecture, this roadmap | - | 2 |
| **P1** First release | ... | 3 | 5 |
| **P2** Second release | ... | 2 | 5 |

**Estimate: about N working days**, between LOW and HIGH. It is an
estimate, not a commitment, and each phase corrects it when it ends.

## Out of scope, kept on record

Rows of the inventory that are out of the phases keep their row and their
reason. Taking one back in is a new decision in [decisions.md](decisions.md).
