---
name: record-decision
description: Use when the project owner takes, changes, confirms or replaces a decision, when a task conflicts with an existing decision, or when you settle something the owner left unspecified. Records it in docs/decisions.md and the project log with its reason and consequences, and never takes a decision that belongs to the owner.
---

# Record a decision

Rule 3 of AGENTS.md says who decides. The goal, the scope, a conflict with
a decision, a boundary of the architecture and what cannot be undone or
costs money belong to the owner. What the owner left unspecified and the
work needs, you settle and record as assumed.

## When a task conflicts with a decision

Stop the conflicting part and ask the owner, in one message: the decision
by id, what the task asks, why the two conflict, and the options with the
one you recommend. Keep working on what does not conflict. Do not resolve
it in code, and do not interpret your way around it.

## When you settle what the owner left open

Record it as below with the status `Current (assumed, not contested)` and
the reason for your choice, and list it in your report. Do not record the
how of the code: a choice needs a row when the owner could reasonably
have wanted something else and would notice the difference.

## When the owner decides

1. **`docs/decisions.md`**: add a row at the top of "Current" with the
   next free `D-nnn`, the date, the decision in one or two sentences, and
   `Current`. When the owner confirms an assumed decision, change its
   status to `Current`.
2. **If it replaces a decision**, never erase the old one: set its status
   to `Replaced by D-nnn` and move it to "Replaced".
3. **`docs/project-log.md`**, section "Decisions, with their reasons and
   consequences": a short entry with **Decision**, **Why** (the owner's
   words where they exist), **What followed** (the work it causes or rules
   out) and **Consequences** (cost, rework, risk). If it replaced another,
   add a paragraph to "What changed direction, and what it cost".
4. **Ripple**: update `docs/goals.md`, `docs/roadmap.md`,
   `docs/engineering.md`, the specifications, inventory rows and backlog
   rows that the decision changes; a dropped backlog row gets `closed_by`
   = the decision id.
5. **Report**: name the decision id and every page you changed.
