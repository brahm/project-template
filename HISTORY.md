# Agent project kit history

What changed in the kit, newest first, one line per change. A project made
from the template reads this file to learn what is newer than its own kit
version (`docs/kit.md` in the project, and the `update-from-template`
skill).

## Changes in 1.5.1 (2026-11-24)

* Added: Installing from a prompt. Pasted in a coding agent opened in the
  project's folder, a short prompt has it clone the kit and follow
  `INSTALL-AGENT.md`: check the tools and the GitHub sign-in, tell a new
  project from one under way, ask once, run `install.sh` with every
  value, and go on with `start-project` in the same conversation. The
  token of `claude setup-token` stays out of the conversation: the owner
  runs `scripts/setup-github.sh` in a terminal of their own.
  `README.md`, `LEIA-ME.md`, `INSTALL.md` and `INSTALACAO.md` lead with it.
* Changed: `install.sh new .` installs in the current folder when it is
  empty, or holds only an empty git repository, Claude Code's
  `.claude/settings.local.json` or `.DS_Store`.

## Changes in 1.5.0 (2026-11-24)

* Added: `install.sh`, one command for the whole installation. `new NAME`
  makes the project from the template, fills it with the owner's
  defaults, creates a private GitHub repository, pushes the first commit
  and turns the automatic review on; `existing` adds the kit to a project
  under way on a branch, never overwriting a file (its `AGENTS.md`,
  `CLAUDE.md`, `.claude/settings.json`, `.gitignore` and `CODEOWNERS` get
  the kit's part added, a workflow of the same name is added as `kit-`);
  `update` takes the newest kit for the user and says what a project
  needs; `github` and `user` run one part alone. Each can be run again.
  It also runs alone, fetching the kit: `bash <(curl -fsSL .../install.sh)`.
* Added: `scripts/setup-github.sh` turns the automatic review on for a
  repository: it saves the token of `claude setup-token` as the secret
  `CLAUDE_CODE_OAUTH_TOKEN` through a pipe (never on disk or on a command
  line), and writes the ruleset `agent-kit: main` (pull requests, the
  checks `Review` and `checks.yml` required, Code Owners for `.github/`,
  no approval count since a personal account cannot approve its own, the
  admins' bypass only through a pull request). On GitHub Free with a
  private repository it says that rulesets are not available and goes on.
* Added: `INSTALL.md` and `INSTALACAO.md`, the manual for installing the
  kit in a new project or in one under way, and for updating it.
* Changed: `start-project` adopts a project under way: the code is the
  brief, and the files the installer kept are merged with the kit's.
  `init-project.sh` points to `scripts/setup-github.sh`.

## Changes in 1.4.1 (2026-11-24)

* Changed: The automatic review runs on the owner's Claude Pro or Max
  plan. The secret `CLAUDE_CODE_OAUTH_TOKEN`, made by `claude
  setup-token`, is the way `docs/kit.md`, `README.md`, `LEIA-ME.md`,
  `start-project`, `init-project.sh` and the workflow's notice now give
  to turn it on, step by step. An API key, `ANTHROPIC_API_KEY`, still
  works as the alternative for organisations that pay the API by use.

## Changes in 1.4.0 (2026-11-24)

* Added: The Second Brain, `docs/brain/`: what the project knows, one
  Markdown note per subject, in the Zettelkasten way (one idea per note,
  linked notes) kept as an agent-maintained wiki. Each note opens with
  the current truth and cites decisions, lessons and rows by id instead
  of copying the logs; dates, estimates and changes stay in their
  records. `docs/brain/README.md` has the method and the index.
* Added: `scripts/brain.py`: `find WORDS` searches the notes and every
  record at once, `index` writes the index, `check` (in `check-all.sh`)
  keeps the notes well formed, and `nudge`, a Claude Code Stop hook in
  `.claude/settings.json`, reminds the agent once when a piece of work
  changed files and no note. `check-docs.py` checks the ids the notes
  cite, and `status.py` points to the brain.
* Added: The `update-brain` skill. Rule 1 of `AGENTS.md` has the agent
  search the brain before a task; `plan-task-set`, `close-task-set` and
  `start-project` read, review and seed it at their moment.

## Changes in 1.3.0 (2026-11-24)

* Added: An automatic review of every pull request before the merge.
  `.github/workflows/review.yml` has Claude Code read the change for
  bugs, security problems, optimisations and the project's rules, and
  `scripts/review-report.py` posts one comment, updated on every push,
  that says what must be fixed or that the change passed; a blocking
  finding fails the check `Review`. It needs the secret
  `ANTHROPIC_API_KEY`, and is skipped with a notice without it.
  `docs/kit.md` says how to turn it on and make it required;
  `docs/engineering.md`, `close-task-set` and `start-project` say what
  the agent does with it. The model gets the change as files, reads only
  the checkout, which keeps no token, and has no shell; the copy of the
  script on the base branch judges the result, neutralises links, images
  and code fences, and withholds a result that holds a secret; and
  `init-project.sh` writes `.github/CODEOWNERS` so that a change to the
  review waits for the owner.
* Fixed: `scripts/check-docs.py` names a page that is not UTF-8 instead
  of stopping with a traceback, and `scripts/dashboard.py` runs without
  git installed.
* Fixed: Without GitHub, the dashboard also lists the pull requests that
  were squashed or rebased (a commit "Title (#N)"), not only merge commits.
* Fixed: The dashboard is published again when `docs/decisions.md`
  changes, since it lists the decisions waiting for the owner.
* Changed: `checks.yml` gives the base branch to its script through the
  environment instead of writing it into the command, and
  `close-task-set` and `docs/dashboard/README.md` write the dashboard
  fragment to `_site/`, which also exists on Windows, instead of `/tmp/`.
* Added: The kit reviews its own pull requests with the same workflow:
  `tools/build-kit.py` copies the template's `review.yml` to the kit's
  `.github/workflows/`, with the kit's paths, and its `--check` compares
  the skill zips by their files, so that another zlib does not make them
  look stale.
* Fixed: `init-project.sh` checks the dashboard language, the time zone,
  the repository and the licence before it changes any file, so that a
  bad value no longer leaves the project half filled.

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
