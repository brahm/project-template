---
name: close-task-set
description: Use at the end of every set of tasks (a pull request, a phase or a thread of work), before the last commit and the final report. Updates the inventory, backlog, dashboard, project log and HISTORY.md, then reports to the owner.
---

# Close a set of tasks

Keep the four records current before the last commit. All are kept for the
whole life of the project.

1. **Inventory**: set the status of every row you touched
   (`docs/inventory/*.tsv`). Done means `status` Done and `review` `-`,
   and only after `validate-against-reference`. Leave the phase in
   `phase`.
2. **Phases**: update `docs/dashboard/phases.tsv` if a phase started
   (`in-progress`, `started` = today) or ended (use `close-phase`).
3. **Backlog**: every unfinished piece has a row (`defer-work`); rows you
   finished are `done` with `closed_by`. Run
   `python3 scripts/check-backlog.py`.
4. **Checks**: run `scripts/check-all.sh` once. Report failures as they
   are; never loosen a test to pass.
5. **Dashboard**: run
   `python3 scripts/dashboard.py --record --artifact /tmp/dashboard.html`,
   commit `docs/dashboard/history.tsv`, `changes.tsv` and `snapshot.tsv`.
   If the owner has a hosted page (see `docs/dashboard/README.md`),
   republish the file **at the same address**; never create a second page.
6. **Project log** (`docs/project-log.md`): a dated timeline entry: what
   was done with its pull requests, what changed, each decision with its
   reason, what followed and the consequences, and what was left undone
   and where it went. Decisions also go through `record-decision`. If the
   owner keeps a translated copy of the log elsewhere, update it too.
7. **HISTORY.md**: one line per change under "Changes since" the last
   release: `Added:`, `Changed:`, `Fixed:` or `Removed:`, plain words for
   a visitor, with the pull request number.
8. **Report** with `report-to-owner`.
