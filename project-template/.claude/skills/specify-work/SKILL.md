---
name: specify-work
description: Use before building an item whose behaviour is not fully defined by a reference, an existing specification or the owner's words, and for any task larger than a small fix. Writes the acceptance criteria, finds what was left unspecified, settles it or asks, and records the assumptions, so that nothing is built on an unwritten guess.
---

# Specify the work before building it

The owner will not think of everything, and should not have to. Finding
what was not said is part of the task. Size the specification to the
work (`docs/specs/README.md`, "When an item gets a page"): a small fix
needs only its test, an item the reference defines needs only its
reference case, and anything else gets a page.

1. **Write the goal** in one or two sentences, in the owner's words where
   they exist: who needs this, and what changes for them.
2. **Write the acceptance criteria**: numbered sentences that a test or a
   comparison can check (`AC-1`), for the normal path and for the empty,
   the limit and the failure cases.
3. **Go through "What is usually left out"** in `docs/specs/README.md`.
   For each line that applies and that neither the brief nor
   `docs/engineering.md` answers, you have found a gap.
4. **Settle each gap** by rule 3 of AGENTS.md. Most are yours: choose
   what serves the goals best, record it with `record-decision` as
   assumed, and list it under "Assumptions". What belongs to the owner
   (scope, cost, something that cannot be undone, a conflict with a
   decision) goes under "Questions for the owner" with the options and
   the one you recommend. Ask once, and keep working on what does not
   depend on the answer.
5. **Say what is out of the item**, so that it is not built by accident.
   What is put off gets a backlog row (`defer-work`).
6. **Say how it will be checked**: the tests of each criterion, and the
   reference when there is one.
7. **Link the page** from the `note` of the inventory row, and cite the
   criteria in the tests (`F-012 AC-3`).

Keep the page short and true. When the behaviour changes, change the page
in the same pull request.
