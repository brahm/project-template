---
name: start-project
description: Use when starting a new project from this template, or when the owner gives a brief for a new project. Turns the brief into goals, first decisions, an inventory, a roadmap with estimates, and the verification plan.
---

# Start a project from the brief

1. **Read the brief** and ask the owner only what blocks planning: the
   target ("done" means what, measured against which reference), what is
   out of scope, the technology, the languages (repository and owner).
2. **`docs/goals.md`**: the target and its rules, each rule pointing to a
   decision.
3. **`docs/decisions.md`**: one row per decision the brief contains,
   dated today, status `Current`; assumptions you made are
   `Current (assumed, not contested)` and listed to the owner.
4. **`docs/inventory/<track>.tsv`**: every item of the target, from the
   reference (manuals, specification, the existing product), one row each,
   with scope (`In`, `Out: reason`, `N/A`), status `Missing`, and a phase.
   Out-of-scope rows stay. Name the tracks in `docs/dashboard/config.toml`.
5. **`docs/roadmap.md`**: phases in the table form the dashboard reads,
   ordered so a common base comes first, each with its row count and an
   estimate in days; the total with a low, likely and high range. Copy
   the range to `docs/dashboard/forecast.tsv` and list the phases in
   `docs/dashboard/phases.tsv`.
6. **`docs/verification.md`**: the references, where each runs, and how
   parity documents are made.
7. **`docs/architecture.md`**: the parts and their boundaries, as
   checkable sentences.
8. **Project log**: the first timeline entry and the reasons of the first
   decisions; **HISTORY.md**: the first lines.
9. Run `python3 scripts/check-backlog.py` and
   `python3 scripts/dashboard.py --record`, then report with
   `report-to-owner`, listing every assumption.
