---
name: close-phase
description: Use when a phase of the roadmap is about to end. Works its backlog to zero, runs the closing checks, marks the phase done, corrects the forecast, looks at the lessons and the template, and tells the owner what moved.
---

# Close a phase

A phase ends with its backlog at zero.

1. **List the open backlog** of the phase: rows of
   `docs/backlog/deferred.tsv` with `status` open and `to_phase` this
   phase or `end-of-phase`. Also list the phase's inventory rows not done.
2. **Work them**, in priority order (`plan-task-set`). Each one done gets
   `status` done and `closed_by`.
3. **What still cannot be done** moves to a named later phase, with a new
   reason; never `end-of-phase` again. Tell the owner each item and its
   new phase.
4. **Run** `python3 scripts/check-backlog.py --phase <PHASE>` (must pass)
   and `scripts/check-all.sh`.
5. **Mark the phase done** in `docs/dashboard/phases.tsv` with `ended` =
   today, and set the next phase to `in-progress` if work on it starts.
6. **Correct the estimate**: the real days of the phase against its
   estimate. Update `docs/roadmap.md` and, if the total changes,
   `docs/dashboard/forecast.tsv`; say so in the project log.
7. **Ask the owner about the assumed decisions** of the phase: list the
   rows of `docs/decisions.md` still `Current (assumed, not contested)`,
   in one message, so that each is confirmed or replaced.
8. **Look back.** Give every `open` row of `docs/lessons.md` its guard
   (`capture-lesson`), and check the template for a newer version and
   for lessons to take to it (`update-from-template`).
9. **Finish with `close-task-set`**.
