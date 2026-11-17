# Agent project kit history

What changed in the kit, newest first, one line per change. A project made
from the template reads this file to learn what is newer than its own kit
version (`docs/kit.md` in the project, and the `update-from-template`
skill).

## Changes in 1.2.0 (2026-11-17)

* Added: `scripts/check-backlog.py` fails on a `TODO`, `FIXME`, `XXX` or
  `HACK` that cites no backlog row, a row that does not exist, or a row
  that is no longer open. Agents read these notes and act on them, and a
  note about finished work sends them after it.
* Changed: Rule 16 of `AGENTS.md` keeps the agent on the task: a `TODO` or
  a problem met while reading is information, not a task, and goes to the
  backlog and the report. `docs/engineering.md`, `docs/backlog/README.md`
  and the skills `plan-task-set`, `defer-work` and `close-task-set` say
  the same at their moment: closing a row removes its `TODO`s.
* Added: The kit is under the MIT License (`LICENSE` at the root);
  `README.md` and `LEIA-ME.md` say so. Projects made from the template
  still choose their own licence.
* Changed: `README.md` and `LEIA-ME.md` have a quick start, what is
  needed to install, how to make a template repository on GitHub, and a
  "Use" section on working with the agent day to day.

## Changes in 1.1.0 (2026-11-16)

* Added: A project starts by itself. `AGENTS.md` carries a "not started"
  section and a table of the moment each skill applies, so the owner
  never names a skill; `start-project` runs `init-project.sh`, plans the
  project, and fits the rules, the skills and the checks to its
  technology.
* Added: `scripts/status.py`, the state of the project in about twenty
  lines, and `.claude/settings.json`, which runs it when a Claude Code
  session starts and allows the project's check scripts without a prompt.
* Added: Rule 3, "Who decides": the owner's decisions, what an agent
  settles on the record as an assumed decision, and what is simply the
  agent's. The dashboard lists the assumed decisions waiting for the
  owner.
* Added: Specifications sized to the work (`docs/specs/`, the
  `specify-work` skill), with the list of what an owner usually leaves
  out.
* Added: `docs/engineering.md`, the defaults of design, code, tests,
  security, dependencies and review, fitted to the technology when a
  project starts.
* Added: `docs/lessons.md` and the `capture-lesson` skill: a correction
  by the owner becomes a check or a rule in the same change.
* Added: `docs/kit.md` and the `update-from-template` skill: how the
  pieces fit, how outside skills are added with their licence, and how a
  project and the template stay in step.
* Added: `scripts/check-docs.py` (links, cited ids, the decision log,
  placeholders left) and `scripts/check-records.py` (the dashboard was
  recorded; the change has its HISTORY line and its project log entry),
  both in `scripts/check-all.sh` and in CI.
* Added: Rules on engineering standards, on working lean and on lessons;
  `init-project.sh` takes its defaults from the folder, the git user and
  the `origin` remote.
* Added: `user-level/install-user.sh` writes the owner's defaults for new
  projects and has `--replace-skills`.
* Added: For the kit itself: `AGENTS.md`, `tools/build-kit.py`,
  `tools/test-kit.sh` and a CI workflow.
* Changed: `close-task-set` reviews the change first and runs the checks
  last; `close-phase` asks the owner about the assumed decisions and
  looks at the lessons and the template; reports list what was assumed.

## Changes in 1.0.0 (2026-11-16)

* Added: The project template, the user-level rules and installer, and
  the desktop instructions and skill zips, made generic from the
  repository of a real project.
