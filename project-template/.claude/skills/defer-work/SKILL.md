---
name: defer-work
description: Use whenever something you were asked to do is not finished, is skipped, or moves to a later phase. Records it in docs/backlog/deferred.tsv and makes sure the owner is told which item moved to which phase.
---

# Record work left undone

Nothing is dropped silently. Each time a piece of the task is not done, or
is moved to a later phase:

1. **Add a row** to `docs/backlog/deferred.tsv` (tab-separated, keep the
   `#` header lines), in the same change:
   - `id`: the next free `B-nnn` (never reuse one);
   - `date`: today, `YYYY-MM-DD`;
   - `item`: what was not done, in one sentence;
   - `rows`: the inventory ids it belongs to, or `-`;
   - `task_set`: this pull request, phase or thread;
   - `reason`: why, honestly (no time, blocked on X, needs a decision);
   - `from_phase`: the phase it belonged to;
   - `to_phase`: the phase it moves to, or `end-of-phase`;
   - `status`: `open`; `closed_by`: `-`.
2. **Mark the code only with the row.** A `TODO` left in the code cites
   it, `TODO(B-nnn)`; a bare `TODO` fails the check.
3. **Run** `python3 scripts/check-backlog.py` and fix what it reports.
4. **Update the inventory row** if its status or phase changed.
5. **Tell the owner** in the report, explicitly, in a line of its own:
   "Left undone: <item> (B-nnn), moved to phase <phase>, because <reason>."
   Do this for every row, even small ones. Never bury it in a summary.

When you later finish a backlog row, set `status` to `done` and
`closed_by` to the commit or pull request, and remove every
`TODO(B-nnn)` of that row in the same change: a note about finished work
sends the next agent after it. A row is `dropped` only by a
decision of the owner, named in `closed_by`. Rows are never deleted.
