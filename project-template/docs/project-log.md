# Project log

The history of {{PROJECT_NAME}} from its first day, written to be read on
its own: what was done, each decision with its reason, and what each
decision led to. It is the source for posts about the project and for the
project page, and the long form of [decisions.md](decisions.md), which
keeps one row per decision.

**This is a living document.** Whoever closes a set of tasks adds an entry
to [the timeline](#timeline) and, when a decision was taken or replaced, to
[the decisions](#decisions-with-their-reasons-and-consequences). See
[Keeping this log](#keeping-this-log).

Dates are the owner's local dates ({{TIMEZONE}}).

## {{PROJECT_NAME}} in one paragraph

What it is, who makes it and how (for example: one person who decides and
approves, with an AI model that writes the code, the tests and the
documentation), and where it stands.

## Why the project exists

In the owner's words where they exist.

## Timeline

### YYYY-MM-DD: planning

- What was delivered, with its pull requests.
- What was decided (D-001), in one line; the reason goes below.
- What was left undone and the phase it moved to (B-001).

## Decisions, with their reasons and consequences

### D-001: the target (YYYY-MM-DD)

**Decision.** ...

**Why.** In the owner's words where they exist.

**What followed.** The work it caused, what it ruled out.

**Consequences.** What it cost or saved, added when they show, even weeks
later.

## What changed direction, and what it cost

Decisions that replaced earlier ones, and the rework each caused.

## Where the project stands, and what comes next

Dated.

## Keeping this log

This log is one of the documents updated throughout the project, with the
inventory, the backlog register, the dashboard and HISTORY.md.

1. At the end of each set of tasks, add an entry to the timeline: the
   date, what was delivered with its pull requests, and what was left
   undone and where it went. Add the same changes, one short line each, to
   [HISTORY.md](../HISTORY.md).
2. When the owner takes a decision, or one is replaced, add it to
   [decisions.md](decisions.md) first, then here with its reason, in the
   owner's words where they exist, and its consequences. Never rewrite an
   old entry to fit a new decision: add the new one and say what it
   replaced.
3. When a consequence only shows later (an estimate missed, a decision
   that cost rework), add it to the decision it belongs to and to "What
   changed direction".
4. Keep the numbers dated.
