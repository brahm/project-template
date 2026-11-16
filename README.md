# Agent project kit

A project template and a set of rules for building software with coding
agents, extracted from a real project where an owner decides and approves
and an AI model plans, writes the code, the tests and the documentation.
It works with Claude Code, Claude desktop, Codex CLI, ChatGPT desktop, Pi
and other agents that read `AGENTS.md`.

(Português: [LEIA-ME.md](LEIA-ME.md).)

## What is in it

| Folder | What it is | For |
| --- | --- | --- |
| `project-template/` | A repository to start new projects from: `AGENTS.md` (the single source of the rules), `CLAUDE.md` pointing to it, `docs/` (goals, decisions, architecture, roadmap, verification, engineering standards, specifications, inventory, backlog, project log, lessons, writing style, dashboard), `HISTORY.md`, `CONTRIBUTING.md`, eleven skills, a session hook, scripts, PR and issue templates, CI, `REUSE.toml`, and `init-project.sh` | Every new repository |
| `user-level/` | The working rules for your user (all projects), your defaults for new projects, and `install-user.sh`, which adds them and the skills to Claude Code, Codex and Pi without overwriting your files | Your computer, once |
| `desktop/` | Text to paste into the instructions of a Claude or ChatGPT Project, and each skill zipped for upload to Claude | Chat apps without a repository |
| `tools/`, `AGENTS.md`, `HISTORY.md` | For working on the kit itself: the rules, the script that rebuilds the zips, the test that makes a project from the template, and the kit's versions | Whoever changes the kit |

## How it is meant to work

The kit is not a harness. It does not tell the agent how to plan or how
to code; a good model does that well on its own, and a method imposed on
it mostly takes its judgement away. The kit names what must not be
forgotten when one person works with an agent, and then makes sure it is
not: by a check where a check can do it, by a short skill at the moment
it matters, and by a rule only when nothing else will.

- **You never invoke a skill.** `AGENTS.md` lists the moment each one
  applies, and the agent opens it when the moment comes. A repository
  just made from the template says "not started", and the agent plans the
  project from your first message.
- **The agent decides what you left open, and tells you.** The goal, the
  scope and what cannot be undone are yours. What you did not specify,
  the agent settles, records as an assumed decision, and lists in its
  report and on the dashboard for you to confirm or replace.
- **A session starts from the state, not from reading.**
  `scripts/status.py` prints the phase, what comes next, the backlog and
  what waits for you in about twenty lines; Claude Code runs it by
  itself.
- **What keeps being forgotten becomes a check.** Broken links, ids that
  do not exist, a dashboard not recorded, a change without its HISTORY
  line: `scripts/check-all.sh` and the CI fail on them.
- **Your corrections become guards.** When you have to correct the
  agent, it records the lesson and adds what prevents it, and proposes it
  to the template when it would help every project.

## The rules, in short

- **Start from the state** (`scripts/status.py`); **the skills apply by
  themselves**.
- **Who decides**: the owner, the goal and the scope; the agent, on the
  record, what was left open; the agent, the how.
- **Prioritize before executing**, and say the order.
- **Consult before conflicting** with a decision of the owner; never pick a
  side silently.
- **Specify before building**, as much as the work needs: acceptance
  criteria a test can check, and what an owner usually leaves out.
- **Engineering standards** (`docs/engineering.md`): the simplest design,
  logic apart from input and output, failures handled, no secret in the
  repository, a reason for every dependency.
- **Validate against a reference**, and record the result.
- **Nothing dropped silently**: what is left undone or moved goes to the
  backlog register (`docs/backlog/deferred.tsv`) and the report names the
  item and the phase it moved to.
- **A phase closes with its backlog at zero** (`scripts/check-backlog.py --phase`).
- **At the end of each set of tasks**, update the inventory, the dashboard
  (`scripts/dashboard.py --record`), the project log (what, why, what
  followed, consequences) and `HISTORY.md` (one line per change, in the
  style of Textpattern's HISTORY file).
- **Decisions belong to the owner**, logged with an id, never erased.
- **Tests**: those of the change while working, all once before finishing;
  a bug is fixed with a test that fails first; never loosened to pass.
- **Work lean**: read only what the task touches; tokens and the owner's
  attention are part of the cost.
- **A lesson becomes a guard**: a check before a rule, a sharper rule
  before a new one.
- **Comments and writing**: a module comment per file, a doc comment per
  public item, the why of anything not obvious; plain words, outcome first.

## The skills

The agent applies each one at its moment; you do not call them.

| Skill | When |
| --- | --- |
| `start-project` | A repository just made from the template, or a brief for a new project: placeholders, goals, decisions, inventory, roadmap, verification, and the rules, skills and checks fitted to the technology |
| `plan-task-set` | Before any work: find it in the plan, check decisions, find what was not said, prioritize |
| `specify-work` | An item whose behaviour no reference defines: acceptance criteria, gaps, assumptions |
| `record-decision` | The owner decides, a task conflicts with a decision, or the agent settles what was left open |
| `defer-work` | Something is left undone or moves phase |
| `validate-against-reference` | Before calling behaviour done |
| `close-task-set` | End of a pull request, phase or thread: review, records, checks and report |
| `close-phase` | End of a phase: backlog to zero, checks, forecast, assumed decisions, lessons |
| `report-to-owner` | Any report or PR description |
| `capture-lesson` | The owner corrects the agent, or a mistake repeats: the lesson and its guard |
| `update-from-template` | The template changed, or a lesson is worth taking to it |

Outside skills are not bundled. `docs/kit.md` in the template says when
one is worth adding (for example `webapp-testing` from
[anthropics/skills](https://github.com/anthropics/skills) for a project
with a web interface), how its licence is checked and recorded, and that
it is read whole first, as code from a stranger. `start-project` adds
only what the project's technology needs.

## Install

### A new project (any agent)

```sh
cp -R project-template my-project      # or push it to GitHub and mark it "Template repository"
cd my-project && git init
```

Then open your agent in the folder and say what you want to build. It
sees that the project has not been started, runs `init-project.sh` with
what it knows (your brief, your defaults, the git user and remote), asks
only what blocks the plan, writes the plan, fits the kit to your
technology and reports what it assumed. To fill the placeholders
yourself first, run `./init-project.sh`, which asks for the name, the
owner, the languages, the time zone and the licence.

`init-project.sh` fills every `{{PLACEHOLDER}}` and sets up each agent
(`--tools all` by default, or a list such as `--tools claude,codex`):

| Agent | What it reads | What the script does |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` (imports `AGENTS.md`), `.claude/skills/`, `.claude/settings.json` (the session hook and the allowed check scripts) | Keeps them |
| Codex CLI (and Codex in ChatGPT) | `AGENTS.md`; skills in `.agents/skills/` | Links `.agents/skills` to `.claude/skills` |
| Pi | `AGENTS.md`; skills in `.pi/skills/` | Links `.pi/skills` to `.claude/skills` |
| Gemini CLI | `GEMINI.md` by default | Writes `.gemini/settings.json` so it reads `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md`, `AGENTS.md` | Writes a pointer |
| Cursor | `AGENTS.md`, `.cursor/rules/` | Writes a rule pointing to it |
| Others (Aider, Zed, Amp, Jules, ...) | Usually `AGENTS.md`; otherwise point them to it (Aider: `--read AGENTS.md`) | Nothing needed |

Use `--copy` instead of links on Windows. The skills are plain Markdown,
and `AGENTS.md` gives their path and their moment, so an agent without
skill support follows them too. Only Claude Code runs the state report by
itself; the other agents run `python3 scripts/status.py` first, as rule 1
says.

### For your user, in every project

```sh
user-level/install-user.sh               # or --tools claude,codex,pi ; --dry-run to see first
```

It appends the working rules between marker lines to `~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md` and `~/.pi/agent/AGENTS.md` (a second run replaces the
block), and copies the skills to `~/.claude/skills`, `~/.codex/skills` and
`~/.pi/agent/skills`, leaving any skill you already have
(`--replace-skills` takes the kit's new version of them). It also asks
once for your defaults for new projects (your name, the languages, the
time zone, the licence, the GitHub account) and writes them below the
rules, so that an agent starting a project does not ask again; edit them
there whenever you like.

### Claude desktop

1. Settings > Capabilities > Skills: upload each zip of `desktop/claude-skills/`.
2. In a Project, paste `desktop/project-instructions.md` (below its line)
   into the instructions, and add the `docs` pages you use as files.
3. Claude desktop's Claude Code tab works on a repository: use the
   template as above.

### ChatGPT desktop

1. In a Project, paste `desktop/project-instructions.md` into the
   instructions and add the `docs` pages as files. ChatGPT has no skill
   upload in Projects; ask it to follow a skill by name and attach that
   `SKILL.md`.
2. Codex (in ChatGPT or the CLI) reads `AGENTS.md` from the repository
   directly.

## The dashboard

`scripts/dashboard.py` builds one HTML page from the repository: items done
per track and phase, what was just done, what comes next, the backlog,
the decisions waiting for the owner, the forecast, the history and a
filterable list. Python 3.11, no
dependencies; English or Brazilian Portuguese (`docs/dashboard/config.toml`).
`--out` writes a page, `--artifact` a fragment for a hosted page such as a
claude.ai Artifact, `--record` stores the day's numbers and changes.
`.github/workflows/dashboard.yml` publishes it with GitHub Pages.

## Changing the kit

`AGENTS.md` at the root has the rules for working on the kit, and
`HISTORY.md` its versions. After a change, `tools/build-kit.py` rebuilds
the skill zips and `tools/test-kit.sh` makes a project from the template
in a temporary folder, runs its checks, and tries each guard on the
mistake it exists for. The CI runs the same test.

## Check that tool locations are current

Agents change their file locations often. The kit was checked on
2026-11-16; if an agent does not pick up its file, look up where it reads
project instructions and skills now and move the link.

## Where it came from, and what was left out

The rules, the documents, the backlog register, the dashboard and its
script come from the repository of an office suite, made generic. Left out
because they belong to that project only: its goals and decisions, its
inventories and parity matrices, its architecture and layer rules, its file
format extension catalogue, its UI test harness, fuzzing, Flatpak and
website workflows, and its interface mockups. They appear here only as the
general rule they followed ("standards first, document every extension";
"keep the architecture's boundaries"). That project had no separate tone
of voice guide: `docs/writing-style.md` was written from the style its
documents follow, and from the owner's rules on reporting. It had no pull
request or issue templates either: the ones here follow its
CONTRIBUTING.md.
