# Instructions for coding agents

You are working on {{PROJECT_NAME}}, {{PROJECT_SUMMARY}}. {{OWNER}} owns
the project: they decide, supervise and approve; you plan, write the code,
the tests and the documentation. Read these rules before changing anything.
They are short on purpose and point to the full pages in [docs](docs/README.md).

This file is the single source of the rules. `CLAUDE.md` and the files of
other agents only point here.

## Before you start

1. **Read the goal.** The target and its rules are in
   [docs/goals.md](docs/goals.md). Out-of-scope items are not implemented
   and are not deleted: they keep their row and their reason.
2. **Find the work in the plan.** Every piece of work belongs to a row of
   the [inventory](docs/inventory/README.md) and to a phase of the
   [roadmap](docs/roadmap.md). Do not start work of a later phase unless the
   task says so. If the work has no row, add one in the same change.
3. **Prioritize before you execute.** List what the task needs, order it
   (what unblocks other work, what the owner asked for first, what carries
   the most risk), say the order in your first report, then work through
   it. Do not start with the easy parts because they are easy.
4. **Check the decisions.** [docs/decisions.md](docs/decisions.md) holds
   every decision of the project. When a task conflicts with one, **stop and
   ask the owner**; do not pick a side in code, and do not quietly work
   around it. The same applies to a request that would undo an earlier
   instruction of the owner.

## While you work

5. **Architecture.** Keep the boundaries described in
   [docs/architecture.md](docs/architecture.md). A change that needs to cross
   one is a decision for the owner, not a shortcut.
6. **Standards first.** Use the platform's standard components, formats and
   conventions when they exist. When you build or extend one, record it
   where the docs say (a component table, an extension catalogue) in the
   same change, so it can be reviewed later.
7. **Comments** follow [CONTRIBUTING.md](CONTRIBUTING.md#comments): a module
   comment per file, a doc comment per public item, the how and the why of
   anything not obvious, and ids of rows and decisions where they explain a
   behaviour.
8. **Tests.** Run the tests of what you changed while you work, and
   `scripts/check-all.sh` once before you finish. Never skip, disable or
   loosen a test to make it pass. Report a failure as it is, with its output.
9. **Validate against the reference.** Behaviour that a reference defines
   (a specification, an existing product, a previous version) is checked
   against that reference, as [docs/verification.md](docs/verification.md)
   says, and the result is recorded. "It looks right" is not a check.
10. **Third-party material.** Do not copy code, assets or definitions whose
    licence does not allow it. Every file has an SPDX header or is covered
    by `REUSE.toml`.

## When something is left undone

11. **Nothing is dropped silently.** If you do not finish something you were
    asked to do, or you move it to a later phase, add a row to
    [docs/backlog/deferred.tsv](docs/backlog/README.md) with the reason and
    the phase it moves to, run `python3 scripts/check-backlog.py`, and **say
    so plainly in your report**: which item, and to which phase it moved.
12. **A phase closes with its backlog at zero.** Before a phase is marked
    done, every open backlog row that moved to it, or to `end-of-phase`, is
    done, or moves to a named later phase with the owner told.
    `python3 scripts/check-backlog.py --phase NAME` must pass.

## When a set of tasks ends

A set of tasks is a pull request, a phase, or a thread of work. Before its
last commit, keep these four records current. They are kept for the whole
life of the project, not only at releases.

13. **Inventory and phases.** Update the status of the rows you touched in
    `docs/inventory/` and of the phase in `docs/dashboard/phases.tsv`.
14. **Dashboard.** Run `python3 scripts/dashboard.py --record` and commit
    what it writes in `docs/dashboard/`. If the project publishes the
    dashboard elsewhere, republish it at the same address, as
    [docs/dashboard/README.md](docs/dashboard/README.md) says.
15. **Project log.** Add an entry to [docs/project-log.md](docs/project-log.md):
    what was done, what changed, each decision with its reason, what
    followed from it and its consequences, and what was left undone.
16. **History.** Add one short line per change to [HISTORY.md](HISTORY.md),
    under "Changes since" the last release, prefixed `Added:`, `Changed:`,
    `Fixed:` or `Removed:`, with its pull request.

## Reporting

17. **Report** to the owner in {{OWNER_LANGUAGE}}: the result first, then what
    it depends on, then what was left undone and where it went. Follow
    [docs/writing-style.md](docs/writing-style.md). Never claim a check you
    did not run.

## Language

Everything in the repository is in {{REPO_LANGUAGE}}: code, comments,
documentation, commit messages. Reports to the owner and the dashboard
are in {{OWNER_LANGUAGE}}.
