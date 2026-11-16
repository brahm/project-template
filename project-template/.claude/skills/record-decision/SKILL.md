---
name: record-decision
description: Use when the project owner takes, changes or replaces a decision, or when a task conflicts with an existing decision. Records it in docs/decisions.md and the project log with its reason and consequences, and never decides on the owner's behalf.
---

# Record a decision of the owner

Decisions belong to the owner. An agent records them; it does not take
them.

## When a task conflicts with a decision

Stop the conflicting part and ask the owner, in one message: the decision
by id, what the task asks, why the two conflict, and the options with the
one you recommend. Keep working on what does not conflict. Do not resolve
it in code, and do not interpret your way around it.

## When the owner decides

1. **`docs/decisions.md`**: add a row at the top of "Current" with the
   next free `D-nnn`, the date, the decision in one or two sentences, and
   `Current`. If you had to assume something to keep working, use
   `Current (assumed, not contested)` and say so to the owner.
2. **If it replaces a decision**, never erase the old one: set its status
   to `Replaced by D-nnn` and move it to "Replaced".
3. **`docs/project-log.md`**, section "Decisions, with their reasons and
   consequences": a short entry with **Decision**, **Why** (the owner's
   words where they exist), **What followed** (the work it causes or rules
   out) and **Consequences** (cost, rework, risk). If it replaced another,
   add a paragraph to "What changed direction, and what it cost".
4. **Ripple**: update `docs/goals.md`, `docs/roadmap.md`, inventory rows
   and backlog rows that the decision changes; a dropped backlog row gets
   `closed_by` = the decision id.
5. **Report**: name the decision id and every page you changed.
