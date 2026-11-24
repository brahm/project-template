---
name: close-task-set
description: Use at the end of every set of tasks (a pull request, a phase or a thread of work), before the last commit and the final report. Reviews the change, updates the inventory, backlog, dashboard, project log and HISTORY.md, runs the checks, then reports to the owner.
---

# Close a set of tasks

Keep the four records current before the last commit. All are kept for the
whole life of the project.

1. **Review your own change**: read the whole diff once by the list
   "Reviewing a change" of `docs/engineering.md`, and fix what you find.
2. **Inventory**: set the status of every row you touched
   (`docs/inventory/*.tsv`). Done means `status` Done and `review` `-`,
   and only after `validate-against-reference`. Leave the phase in
   `phase`.
3. **Phases**: update `docs/dashboard/phases.tsv` if a phase started
   (`in-progress`, `started` = today) or ended (use `close-phase`).
4. **Backlog**: every unfinished piece has a row (`defer-work`); rows you
   finished are `done` with `closed_by`, and their `TODO(B-nnn)` comments
   are gone. A problem you noticed outside the task has a row, not a fix.
5. **Lessons**: if the owner had to correct something, or a mistake
   repeated, it has a row and a guard (`capture-lesson`).
6. **Second Brain**: the notes of the subjects you touched still say the
   truth, and what this work taught is written (`update-brain`).
7. **Dashboard**: run
   `python3 scripts/dashboard.py --record --artifact _site/dashboard.html`,
   commit `docs/dashboard/history.tsv`, `changes.tsv` and `snapshot.tsv`.
   If the owner has a hosted page (see `docs/dashboard/README.md`),
   republish the file **at the same address**; never create a second page.
8. **Project log** (`docs/project-log.md`): a dated timeline entry: what
   was done with its pull requests, what changed, each decision with its
   reason, what followed and the consequences, and what was left undone
   and where it went. Decisions also go through `record-decision`. If the
   owner keeps a translated copy of the log elsewhere, update it too.
9. **HISTORY.md**: one line per change under "Changes since" the last
   release: `Added:`, `Changed:`, `Fixed:` or `Removed:`, plain words for
   a visitor, with the pull request number.
10. **Checks**: run `scripts/check-all.sh` once, after the records: it
    also checks that they were updated. Report failures as they are; never
    loosen a test to pass.
11. **Automatic review**: once the pull request is open, read the comment
    of `.github/workflows/review.yml`. Fix what is blocking or should be
    fixed, or answer in the pull request why a finding is wrong; a
    suggestion not taken that is worth keeping goes to `defer-work`.
12. **Report** with `report-to-owner`, with the verdict of the review.
