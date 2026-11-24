---
name: plan-task-set
description: Use at the start of any task or set of tasks in a project that follows AGENTS.md, before writing code. Finds the work in the inventory and roadmap, checks it against the decisions, finds what was left unspecified, prioritizes it and states the plan.
---

# Plan a set of tasks before executing it

Do this before the first change. It takes a few minutes and prevents
building the wrong thing, in the wrong order, or against a decision. Size
it to the task: a one-line fix needs steps 2, 4 and 8 in your head, not a
written plan.

1. **Start from the state**: the output of `python3 scripts/status.py`.
   Read `docs/goals.md` only if the task touches the target. Run
   `python3 scripts/brain.py find` with the words of the task: what the
   project learned about it before is in the notes it lists.
2. **Find each piece of work in the inventory** (`grep` the id or the
   words in `docs/inventory/*.tsv`): its id, scope, status and phase.
   Work without a row gets a new row (next free id, `scope` In, `status`
   Missing, the phase it belongs to). Work that is `Out: ...` is not
   done: tell the owner and stop that part. A `TODO` or a note met in
   the code is not a piece of the task unless the task names it; its row
   in `docs/backlog/deferred.tsv` says whether it is still open.
3. **Check the phase.** If a piece belongs to a later phase than the one in
   progress (`docs/dashboard/phases.tsv`), do not do it unless the task
   says so; say that you left it.
4. **Check the decisions** (`docs/decisions.md`) and earlier instructions
   of the owner. If the task conflicts with one, **stop and ask** the
   owner, naming the decision by id and the conflict in one sentence.
   Continue only with the parts that do not conflict.
5. **Check the backlog** (`docs/backlog/deferred.tsv`) for open rows that
   moved to this phase: they are part of the work.
6. **Find what was not said.** For each piece whose behaviour no
   reference defines, use `specify-work`. What the owner left open and
   the work needs, you settle and record (rule 3 of AGENTS.md); only what
   belongs to the owner becomes a question.
7. **Prioritize.** Order the pieces:
   1. what the owner said comes first;
   2. what unblocks other pieces;
   3. what carries the most risk or uncertainty (find out early);
   4. the rest, grouped so each pull request stays reviewable.
8. **Decide how each piece will be checked**: its tests, and its
   reference per `docs/verification.md`.
9. **State the plan** to the owner in one short message or checklist: the
   order, what you will not do and why, what you assumed, and any
   question. Then work through it without waiting, unless a step cannot
   be undone or a decision of the owner is needed.
