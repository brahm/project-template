# Inventory

Every item of the target, one row each, with its scope, status and phase.
It is the list the work is planned from, the list the tests cite, and the
source of the dashboard.

Each file of this directory is one **track** (an app, a module, a
component): `main.tsv` to start with. Add a track by adding a file and
naming it in `docs/dashboard/config.toml`.

| Column | Meaning |
| --- | --- |
| `id` | A prefix of the track and a number, never reused (`F-001`) |
| `area` | The area of the target the item belongs to |
| `item` | The feature or the task, in one sentence |
| `scope` | `In`; `Out: reason` (kept on record, not built); or `N/A` (not applicable) |
| `status` | `Done`, `Partial`, `Started` (the base exists, the item does not work yet) or `Missing` |
| `review` | `-`, or why the status must be checked again (the target changed, the check was not against the reference) |
| `phase` | The phase of [roadmap.md](../roadmap.md) that owns the row; `done` for rows finished before the plan; `-` when out of scope |
| `note` | How the item works today, how it was checked, what is missing, or its page in [specs](../specs/README.md) |

An item **counts as done** only when `scope` is `In`, `status` is `Done`
and `review` is `-`. When you finish an item, set `status` to `Done` and
`review` to `-`, and **leave its phase** in `phase`, so that the phase
shows its own progress.

Out-of-scope rows are never deleted: taking one back is a decision.
