# Instructions for coding agents

You are working on {{PROJECT_NAME}}, {{PROJECT_SUMMARY}}. {{OWNER}} owns
the project: they decide, supervise and approve; you plan, write the code,
the tests and the documentation. Read these rules before changing anything.
They are short on purpose and point to the full pages in [docs](docs/README.md).

This file is the single source of the rules. `CLAUDE.md` and the files of
other agents only point here.

<!-- kit:not-started begin -->
## This project has not been started

This repository was just made from the template. Before any other work,
and without waiting to be asked, follow
[the start-project skill](.claude/skills/start-project/SKILL.md), taking
what the owner wrote as the brief. It fills the placeholders, plans the
project, fits the rules, the skills and the checks to it, and deletes this
section.
<!-- kit:not-started end -->

## How the work is run

These rules name what must not be forgotten. Inside them, how to reach the
goal is yours to organise: the owner counts on you to plan, to notice what
was not specified, and to keep the records.

1. **Start from the state and from what is known.** `python3
   scripts/status.py` says in a few lines where the project stands: the
   phase in progress, what comes next, the open backlog, the decisions
   waiting for the owner. Claude Code runs it when a session starts; with
   another agent, run it first. Before a task, and before asking the
   owner anything, `python3 scripts/brain.py find WORDS` finds what the
   project already knows about it: the notes of the
   [Second Brain](docs/brain/README.md), then the records.
2. **The skills apply by themselves.** The owner never has to name one.
   When one of these moments comes, open `.claude/skills/NAME/SKILL.md`
   and follow it:

   | Moment | Skill |
   | --- | --- |
   | The project has not been started | `start-project` |
   | A task arrives, before the first change | `plan-task-set` |
   | The behaviour of an item is not fully defined | `specify-work` |
   | The owner decides, or a task conflicts with a decision | `record-decision` |
   | Something is left undone, or moves to a later phase | `defer-work` |
   | Before calling behaviour done | `validate-against-reference` |
   | A pull request, a thread of work or a phase ends | `close-task-set`, `close-phase` |
   | Any report to the owner | `report-to-owner` |
   | The owner corrects you, or a mistake repeats | `capture-lesson` |
   | You learn something the next session will need | `update-brain` |
   | The template has a newer version | `update-from-template` |

3. **Who decides.**
   - *The owner:* the goal and the scope; anything that conflicts with a
     current decision or an earlier instruction; a change that crosses a
     boundary of the architecture; what cannot be undone or costs money
     (a release, a deletion of data, a paid service, a licence). Stop that
     part, ask once with the options and the one you recommend, and keep
     working on the rest.
   - *You, on the record:* what the owner left unspecified and the work
     needs. Choose what serves the goals best, record it in
     [docs/decisions.md](docs/decisions.md) as `Current (assumed, not
     contested)` with its reason, and list it in your report. The owner
     confirms it or replaces it.
   - *You:* everything else, the how. The code, its comments and the pull
     request are the record.

## Before you start

4. **Read the goal.** The target and its rules are in
   [docs/goals.md](docs/goals.md). Out-of-scope items are not implemented
   and are not deleted: they keep their row and their reason.
5. **Find the work in the plan.** Every piece of work belongs to a row of
   the [inventory](docs/inventory/README.md) and to a phase of the
   [roadmap](docs/roadmap.md). Do not start work of a later phase unless the
   task says so. If the work has no row, add one in the same change.
6. **Prioritize before you execute.** List what the task needs, order it
   (what unblocks other work, what the owner asked for first, what carries
   the most risk), say the order in your first report, then work through
   it. Do not start with the easy parts because they are easy.
7. **Check the decisions.** [docs/decisions.md](docs/decisions.md) holds
   every decision of the project. When a task conflicts with one, **stop and
   ask the owner**; do not pick a side in code, and do not quietly work
   around it. The same applies to a request that would undo an earlier
   instruction of the owner.
8. **Specify before you build**, as much as the work needs. Behaviour that
   a reference defines needs nothing more, and a small fix needs only its
   test. Anything else gets acceptance criteria that tests can check, in
   a page of [docs/specs](docs/specs/README.md). Look for what an owner
   tends to leave out (failures, limits, data, security, accessibility),
   settle each point by rule 3, and never build on a guess you did not
   write down.

## While you work

9. **Architecture.** Keep the boundaries described in
   [docs/architecture.md](docs/architecture.md). A change that needs to cross
   one is a decision for the owner, not a shortcut.
10. **Standards first.** Use the platform's standard components, formats and
    conventions when they exist. When you build or extend one, record it
    where the docs say (a component table, an extension catalogue) in the
    same change, so it can be reviewed later.
11. **Engineering standards.** Design and write by
    [docs/engineering.md](docs/engineering.md): the simplest design that
    meets the criteria, logic apart from input and output, failures
    handled, no secret in the repository, a reason for every dependency.
    Read it before you design a part, add a dependency or review a change.
12. **Comments** follow [CONTRIBUTING.md](CONTRIBUTING.md#comments): a module
    comment per file, a doc comment per public item, the how and the why of
    anything not obvious, and ids of rows and decisions where they explain a
    behaviour.
13. **Tests.** Run the tests of what you changed while you work, and
    `scripts/check-all.sh` once before you finish. A bug is fixed with a
    test that fails first. Never skip, disable or loosen a test to make it
    pass. Report a failure as it is, with its output.
14. **Validate against the reference.** Behaviour that a reference defines
    (a specification, an existing product, a previous version) is checked
    against that reference, as [docs/verification.md](docs/verification.md)
    says, and the result is recorded. "It looks right" is not a check.
15. **Third-party material.** Do not copy code, assets, skills or
    definitions whose licence does not allow it. Every file has an SPDX
    header or is covered by `REUSE.toml`.
16. **Work lean, on the task.** Tokens and the owner's attention are part
    of the cost. Open a page of `docs` only when the task touches it,
    search the TSV files with `grep` instead of reading them whole, send a
    long output to a file and read its end, and run independent steps in
    parallel. A `TODO`, a note or a problem met while reading is
    information, not a task: check its backlog row before trusting it, and
    leave what is outside the task to a backlog row and a line in the
    report.

## When something is left undone

17. **Nothing is dropped silently.** If you do not finish something you were
    asked to do, or you move it to a later phase, add a row to
    [docs/backlog/deferred.tsv](docs/backlog/README.md) with the reason and
    the phase it moves to, run `python3 scripts/check-backlog.py`, and **say
    so plainly in your report**: which item, and to which phase it moved.
18. **A phase closes with its backlog at zero.** Before a phase is marked
    done, every open backlog row that moved to it, or to `end-of-phase`, is
    done, or moves to a named later phase with the owner told.
    `python3 scripts/check-backlog.py --phase NAME` must pass.

## When a set of tasks ends

A set of tasks is a pull request, a phase, or a thread of work. Before its
last commit, read your whole change once as a reviewer would
([the review list](docs/engineering.md#reviewing-a-change)), then keep
these four records current. They are kept for the whole life of the
project, not only at releases, and `scripts/check-all.sh` fails while one
of them is behind.

19. **Inventory and phases.** Update the status of the rows you touched in
    `docs/inventory/` and of the phase in `docs/dashboard/phases.tsv`.
20. **Dashboard.** Run `python3 scripts/dashboard.py --record` and commit
    what it writes in `docs/dashboard/`. If the project publishes the
    dashboard elsewhere, republish it at the same address, as
    [docs/dashboard/README.md](docs/dashboard/README.md) says.
21. **Project log.** Add an entry to [docs/project-log.md](docs/project-log.md):
    what was done, what changed, each decision with its reason, what
    followed from it and its consequences, and what was left undone.
22. **History.** Add one short line per change to [HISTORY.md](HISTORY.md),
    under "Changes since" the last release, prefixed `Added:`, `Changed:`,
    `Fixed:` or `Removed:`, with its pull request.

## When something goes wrong

23. **A lesson becomes a guard.** When the owner corrects you, when a check
    or a review catches what a rule should have prevented, or when a
    mistake repeats, record it in [docs/lessons.md](docs/lessons.md) and
    add the guard in the same change: a check before a rule, a sharper
    rule before a new one. The owner should not have to say it twice.

## Reporting

24. **Report** to the owner in {{OWNER_LANGUAGE}}: the result first, then what
    it depends on, then the decisions you assumed, then what was left
    undone and where it went. Follow
    [docs/writing-style.md](docs/writing-style.md). Never claim a check you
    did not run.

## Language

Everything in the repository is in {{REPO_LANGUAGE}}: code, comments,
documentation, commit messages. Reports to the owner and the dashboard
are in {{OWNER_LANGUAGE}}.
