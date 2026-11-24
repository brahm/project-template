---
name: start-project
description: Use at once, without being asked, when a repository was just made from the template (init-project.sh is still at its root, or AGENTS.md still has its "not started" section), or when the owner gives a brief for a new project. Fills the placeholders, turns the brief into goals, decisions, inventory, roadmap and verification, fits the rules, skills and checks to the project's technology, and reports every assumption.
---

# Start a project from the brief

The owner only says what they want to build. The rest is yours, in one
go, without waiting to be told each step. Read the pages you fill; the
scripts and the other skills need no reading now.

1. **Read the brief and the owner's defaults** (the section "Defaults for
   new projects" of your user instructions, when there is one). Work out
   the name, a one-line summary, the owner, the languages, the time zone,
   the licence, the technology, the target and what is out of scope.
2. **Ask once, only what blocks planning**, in one message, each question
   with the answer you would assume: what "done" means and against which
   reference, the scope, the technology, the licence. Everything else you
   settle yourself in step 6. If the owner told you to decide, or cannot
   answer now, go on with your assumptions.
3. **Fill the placeholders.** If `init-project.sh` is at the root, run it
   with every value as an option so that it asks nothing
   (`./init-project.sh --help` lists them; it deletes itself).
   *In a project under way* (`install.sh existing`) the code is the brief,
   what works is `Done`, and you merge the kit into what was kept: one
   `AGENTS.md` without markers, the template's pages, the `kit-` workflows.
4. **`docs/goals.md`**: the target and its rules, each rule pointing to a
   decision. **`docs/decisions.md`**: one row per decision the brief
   contains, dated today, status `Current`.
5. **The plan.** `docs/inventory/<track>.tsv`: every item of the target,
   from the reference (manuals, specification, the existing product) or
   from the brief, one row each, with scope (`In`, `Out: reason`, `N/A`),
   status `Missing` and a phase; out-of-scope rows stay. Name the tracks
   in `docs/dashboard/config.toml`. `docs/roadmap.md`: phases in the table
   form the dashboard reads, a common base first, each with its row count
   and an estimate in days, and the total as a low, likely and high
   range; copy the range to `docs/dashboard/forecast.tsv` and list the
   phases in `docs/dashboard/phases.tsv`. `docs/verification.md`: the
   references, where each runs, how parity documents are made.
   `docs/architecture.md`: the parts and their boundaries, as checkable
   sentences.
6. **Settle what the brief left out.** Go through `docs/engineering.md`
   and the list "What is usually left out" of `docs/specs/README.md` for
   the project as a whole. Delete the sections that do not apply, and
   fill "The technology of this project". Each choice the owner did not
   make is a decision `Current (assumed, not contested)` with its reason.
7. **Fit the checks.** Put the format, lint, test and documentation
   commands of the technology in `scripts/check-all.sh` and
   `.github/workflows/checks.yml`, the build and test commands in
   `CONTRIBUTING.md`, and the technology's entries in `.gitignore`. They
   must pass on the empty project. Keep `.github/workflows/review.yml`,
   the automatic review; if it has no token yet, the report tells the
   owner to run `scripts/setup-github.sh` (`docs/kit.md`).
8. **Fit the skills**, as `docs/kit.md` says. The kit's skills are
   written for any technology: do not read them all looking for changes.
   Add a skill for a procedure this project will repeat (running the
   application, making a reference case, releasing), and an outside
   skill only when the technology clearly needs it.
9. **Remove the template's marks**: the example rows of the inventory, of
   the backlog and of `docs/lessons.md`, and the section between the
   `kit:not-started` lines of `AGENTS.md`.
10. **First records**: the first timeline entry of the project log with
    the reasons of the first decisions, and the first lines of
    `HISTORY.md`. Seed the Second Brain (`update-brain`): the words of the
    domain in `docs/brain/glossary.md`, and a note for each subject of the
    brief that will be needed again (the reference, the users, an outside
    service). Run `python3 scripts/dashboard.py --record` and
    `scripts/check-all.sh`, and commit (by pull request if `main` is protected).
11. **Report** with `report-to-owner`: the plan in a few lines, every
    assumption with its decision id, and the questions still open.
