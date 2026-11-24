# Agent project kit

A project template and a set of rules for building software with coding
agents, extracted from a real project where an owner decides and approves
and an AI model plans, writes the code, the tests and the documentation.
It works with Claude Code, Claude desktop, Codex CLI, ChatGPT desktop, Pi
and other agents that read `AGENTS.md`.

(Português: [LEIA-ME.md](LEIA-ME.md).)

## Quick start

Open Claude Code in the folder of the project (an empty one for a new
project) and paste:

```text
Install the agent project kit in this folder. Clone
https://github.com/brahm/project-template into a temporary folder and
follow its INSTALL-AGENT.md. What I want to build: ...
```

It installs the kit (a new project or one under way), puts it on GitHub,
and starts the project in the same conversation. The one step left to you
is `scripts/setup-github.sh` in a terminal of your own, which saves the
token of your Claude plan for the automatic review without it passing
through the chat ([INSTALL.md](INSTALL.md#from-a-prompt-the-simplest)).

Or without an agent: one command, on your computer, with `git`, Python 3.11+ and the GitHub CLI
`gh` installed:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/brahm/project-template/main/install.sh) new my-project
```

It makes `my-project` from the template, creates a private GitHub
repository, pushes the first commit, saves the token of your Claude Pro or
Max plan for the automatic review and protects `main`. Then:

```sh
cd my-project && claude                       # or codex, pi, gemini...
```

and tell the agent what you want to build, in your own words. It does the
rest and reports what it assumed. For a project already under way, use
`existing` instead of `new my-project`, in its folder. The manual,
[INSTALL.md](INSTALL.md), has every case, the options and how to update.

## What is in it

| Folder | What it is | For |
| --- | --- | --- |
| `project-template/` | A repository to start new projects from: `AGENTS.md` (the single source of the rules), `CLAUDE.md` pointing to it, `docs/` (goals, decisions, architecture, roadmap, verification, engineering standards, specifications, inventory, backlog, project log, lessons, writing style, dashboard, and the Second Brain), `HISTORY.md`, `CONTRIBUTING.md`, twelve skills, session hooks, scripts, PR and issue templates, CI with an automatic review of each pull request, `REUSE.toml`, and `init-project.sh` | Every new repository |
| `user-level/` | The working rules for your user (all projects), your defaults for new projects, and `install-user.sh`, which adds them and the skills to Claude Code, Codex and Pi without overwriting your files | Your computer, once |
| `install.sh`, `INSTALL-AGENT.md` | The installer, and the procedure an agent follows to run it from a prompt: a new project with its GitHub repository and automatic review, the kit in a project under way, updates ([INSTALL.md](INSTALL.md)) | Your computer, each project |
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
- **Every pull request is reviewed before the merge.** A model that did
  not write the change reads it for bugs, security problems and
  optimisations, and posts on the pull request what must be fixed, or
  that it passed. A blocking finding fails the check, so it cannot be
  merged by mistake. It runs on your Claude Pro or Max plan, and the
  installer turns it on for you.
- **What the project learns is kept, and found in seconds.** The Second
  Brain (`docs/brain/`) holds one Markdown note per subject: how a part
  works, the facts of the domain, the quirks of a service, the cause of
  a problem. The agent writes it as it learns, a hook reminds it, and
  `scripts/brain.py find WORDS` searches the notes and every record at
  once. Decisions, dates and changes stay in their logs; the notes cite
  them by id instead of copying them.
- **Your corrections become guards.** When you have to correct the
  agent, it records the lesson and adds what prevents it, and proposes it
  to the template when it would help every project.

## The rules, in short

- **Start from the state** (`scripts/status.py`) **and from what is
  known** (`scripts/brain.py find`); **the skills apply by themselves**.
- **Write down what was learned** in the note of its subject in the
  Second Brain, citing the records rather than copying them.
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
- **Work lean, on the task**: read only what the task touches; tokens and
  the owner's attention are part of the cost. A `TODO` met on the way is
  information, not a task.
- **No stale notes**: every `TODO`, `FIXME`, `XXX` or `HACK` cites an open
  backlog row, `TODO(B-012)`, and goes away when the row closes
  (`scripts/check-backlog.py`).
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
| `update-brain` | The agent learned something the next session will need: the note of its subject in the Second Brain |
| `update-from-template` | The template changed, or a lesson is worth taking to it |

Outside skills are not bundled. `docs/kit.md` in the template says when
one is worth adding (for example `webapp-testing` from
[anthropics/skills](https://github.com/anthropics/skills) for a project
with a web interface), how its licence is checked and recorded, and that
it is read whole first, as code from a stranger. `start-project` adds
only what the project's technology needs.

## Install

[INSTALL.md](INSTALL.md) is the manual: what you need, a new project, a
project under way, the GitHub part, and updating. In short:

| Command | What it does |
| --- | --- |
| `install.sh new NAME` | A new project in the folder `NAME`: the template filled with your defaults, a private GitHub repository (`--public`, `--no-github`), the first commit pushed, the automatic review turned on |
| `install.sh existing [DIR]` | The kit in a project under way, on a branch `agent-kit`, without overwriting any file: your `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `.gitignore` and `CODEOWNERS` get the kit's part added; a workflow of the same name arrives as `kit-NAME.yml`; the agent then adopts the kit (`start-project`) |
| `install.sh update [DIR]` | The newest kit (`git pull`), its rules and skills for your user, and the kit version of the project `DIR` against the newest |
| `install.sh github [DIR]` | Only the GitHub part, `scripts/setup-github.sh`: the secret `CLAUDE_CODE_OAUTH_TOKEN` and the ruleset of `main` |
| `install.sh user` | Only the rules and skills for your user, `user-level/install-user.sh` |

Run it from a clone of the kit (`git clone
https://github.com/brahm/project-template agent-kit`, then
`agent-kit/install.sh ...`), or alone with `bash <(curl -fsSL
https://raw.githubusercontent.com/brahm/project-template/main/install.sh)
...`, which fetches the kit first. Every command can be run again: what is
done is kept and what is missing is done.

### What the installer sets up for each agent

`init-project.sh`, which the installer runs, sets up each agent
(`--tools all` by default, or a list such as `--tools claude,codex`):

| Agent | What it reads | What the script does |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` (imports `AGENTS.md`), `.claude/skills/`, `.claude/settings.json` (the hooks that print the state when a session starts and recall the Second Brain when the agent stops, and the allowed check scripts) | Keeps them |
| Codex CLI (and Codex in ChatGPT) | `AGENTS.md`; skills in `.agents/skills/` | Links `.agents/skills` to `.claude/skills` |
| Pi | `AGENTS.md`; skills in `.pi/skills/` | Links `.pi/skills` to `.claude/skills` |
| Gemini CLI | `GEMINI.md` by default | Writes `.gemini/settings.json` so it reads `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md`, `AGENTS.md` | Writes a pointer |
| Cursor | `AGENTS.md`, `.cursor/rules/` | Writes a rule pointing to it |
| Others (Aider, Zed, Amp, Jules, ...) | Usually `AGENTS.md`; otherwise point them to it (Aider: `--read AGENTS.md`) | Nothing needed |

On Windows, run it in Git Bash or WSL, with `--copy` instead of links.
Claude Code asks once whether you trust the folder; accept it, or the
project's allowed scripts keep asking for permission. Only Claude Code
runs the state report by itself; the other agents run
`python3 scripts/status.py` first, as rule 1 of `AGENTS.md` says.

### Claude desktop and ChatGPT desktop (no repository)

1. Claude: Settings > Capabilities > Skills, and upload each zip of
   `desktop/claude-skills/`. ChatGPT has no skill upload in Projects: ask
   it to follow a skill by name and attach that `SKILL.md`.
2. In a Project, paste `desktop/project-instructions.md` (below its line)
   into the instructions, and add as files the `docs` pages you use.
3. The Claude Code tab of Claude desktop, and Codex, work on a repository:
   use the template as above.

## Use

You talk to the agent as you would to a colleague. The kit makes sure the
things one person tends to forget are not.

| You | The agent |
| --- | --- |
| Say what you want, in your words | Finds it in the plan, prioritizes, writes acceptance criteria where nothing defines the behaviour, builds, tests, and keeps the records |
| Read its report | Leads with the result, then what it checked, then the decisions it assumed, then what it left undone and to which phase it moved |
| Confirm or replace an assumed decision ("D-007 is fine", "use Postgres, not SQLite") | Records it, and changes the plan, the specification and the code that depended on it |
| Correct it | Fixes the mistake, records the lesson in `docs/lessons.md`, and adds the check or the rule that prevents it |
| Say a phase is done, or let it finish | Works the phase's backlog to zero, corrects the forecast, and asks about the decisions still assumed |
| Say the template changed | Brings the new rules, skills and checks into the project without losing what was fitted to it |

What you will look at, besides the reports:

- **The dashboard**: `python3 scripts/dashboard.py --out dashboard.html`
  and open the file. Items done per track and phase, what was just done,
  what comes next, the backlog, the decisions waiting for you, the
  forecast, the history and a filterable list, in English or Brazilian
  Portuguese (`docs/dashboard/config.toml`). `.github/workflows/dashboard.yml`
  publishes it with GitHub Pages; `--artifact` writes a fragment for a
  hosted page such as a claude.ai Artifact.
- **The state in a few lines**: `python3 scripts/status.py`, the same
  summary the agent reads when a session starts.
- **Every check**: `scripts/check-all.sh`, the same as the CI. It fails on
  failing tests, broken links, ids that do not exist, a dashboard not
  recorded, a change without its HISTORY line or project log entry, and
  files without a licence.
- **The automatic review**: one comment on each pull request, updated on
  every push: passed, passed with points to read, or blocked, with each
  finding's file, line and fix. It runs on your Claude Pro or Max plan.
  The installer turns it on; in a project made otherwise, run
  `scripts/setup-github.sh`, which saves the token of `claude
  setup-token` as the secret `CLAUDE_CODE_OAUTH_TOKEN` and makes the
  check `Review` required on `main`, with "Require review from Code
  Owners", so that a pull request cannot switch the review off for itself
  (`docs/kit.md` in the template, "The automatic review").
- **The records**: `docs/decisions.md`, `docs/backlog/deferred.tsv`,
  `docs/project-log.md`, `docs/lessons.md` and `HISTORY.md`.
- **What the project knows**: `python3 scripts/brain.py find WORDS`, or
  the index of notes in `docs/brain/README.md`. The notes are plain
  Markdown, so they also open as a vault in Obsidian or any editor.

To keep a project in step with the kit, run `install.sh update` in it,
then tell the agent "update the kit"; it brings the new rules, skills and
checks in without losing what was fitted to the project
([INSTALL.md](INSTALL.md#update)).

## Changing the kit

`AGENTS.md` at the root has the rules for working on the kit, and
`HISTORY.md` its versions. After a change, `tools/build-kit.py` rebuilds
the skill zips and the kit's own copy of the automatic review (its pull
requests are reviewed like a project's, once the secret
`CLAUDE_CODE_OAUTH_TOKEN` is set on the kit's repository), and `tools/test-kit.sh` makes a project from the template
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

## License

The kit is under the [MIT License](LICENSE). A project made from the
template is not bound by it: `init-project.sh` asks for the project's own
licence and records it in the project's `REUSE.toml` and `LICENSES/`.
