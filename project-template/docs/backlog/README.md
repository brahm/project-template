# What was left undone

This directory is the memory of the project for work that a set of tasks
was meant to do and did not. Nothing is dropped silently: it is written
here, with the reason, and comes back at the end of the phase.

## The register

[`deferred.tsv`](deferred.tsv) has one row per item, with these columns:

| Column | Meaning |
| --- | --- |
| `id` | `B-` and a number of at least three digits, never reused |
| `date` | The day the item was left undone |
| `item` | The feature or the task, in one sentence |
| `rows` | The inventory rows it belongs to, or `-` |
| `task_set` | The set of tasks (pull request, phase or thread) that left it |
| `reason` | Why it was not done |
| `from_phase` | The phase it belonged to |
| `to_phase` | The phase it moved to, or `end-of-phase` |
| `status` | `open`, `done` or `dropped` (dropped only by a decision in `../decisions.md`) |
| `closed_by` | The commit or pull request that did it, or the decision that dropped it |

## The rules

1. Whoever leaves something undone, person or agent, adds the row in the
   same pull request, and says so in the report to the owner, naming the
   item and the phase it moved to.
2. A phase ends with its backlog at zero: every `open` row whose
   `to_phase` is that phase or `end-of-phase` is done before the phase is
   closed.
3. A row that cannot be done at the end of the phase moves to a named
   later phase, with a new reason, and the owner is told.
4. A row is never deleted. It is closed as `done` with what did it, or
   `dropped` with the decision that dropped it.
5. A `TODO`, `FIXME`, `XXX` or `HACK` in the code cites its row,
   `TODO(B-012)`, and is removed in the change that closes the row. An
   agent reads every note it meets and may act on it, so a note about
   finished or unrecorded work costs time and leads it astray.
6. `scripts/check-backlog.py` checks the file: the columns, unique ids, a
   reason on every row, and `closed_by` on every row that is not open.
   It also reads the files in git and fails on a marker that cites no
   row, a row that does not exist, or a row that is not open. Markdown
   pages and the paths in its `NOT_SCANNED` list are left out; add there
   the code of others kept in the repository. With `--phase NAME` it
   fails while that phase has open rows, which is the check that closes a
   phase.
