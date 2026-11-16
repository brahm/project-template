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
| `project-template/` | A repository to start new projects from: `AGENTS.md` (the single source of the rules), `CLAUDE.md` pointing to it, `docs/` (goals, decisions, architecture, roadmap, verification, inventory, backlog, project log, writing style, dashboard), `HISTORY.md`, `CONTRIBUTING.md`, eight skills, scripts, PR and issue templates, CI, `REUSE.toml`, and `init-project.sh` | Every new repository |
| `user-level/` | The working rules for your user (all projects) and `install-user.sh`, which adds them and the skills to Claude Code, Codex and Pi without overwriting your files | Your computer, once |
| `desktop/` | Text to paste into the instructions of a Claude or ChatGPT Project, and each skill zipped for upload to Claude | Chat apps without a repository |

## The rules, in short

- **Prioritize before executing**, and say the order.
- **Consult before conflicting** with a decision of the owner; never pick a
  side silently.
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
  never loosened to pass.
- **Comments and writing**: a module comment per file, a doc comment per
  public item, the why of anything not obvious; plain words, outcome first.

## The skills

| Skill | When |
| --- | --- |
| `start-project` | A new project from a brief: goals, decisions, inventory, roadmap, verification |
| `plan-task-set` | Before any work: find it in the plan, check decisions, prioritize |
| `defer-work` | Something is left undone or moves phase |
| `record-decision` | The owner decides, or a task conflicts with a decision |
| `validate-against-reference` | Before calling behaviour done |
| `close-task-set` | End of a pull request, phase or thread: records and report |
| `close-phase` | End of a phase: backlog to zero, checks, forecast |
| `report-to-owner` | Any report or PR description |

## Install

### A new project (any agent)

```sh
cp -R project-template my-project      # or push it to GitHub and mark it "Template repository"
cd my-project && git init
./init-project.sh                      # asks for name, owner, languages, time zone, licence
```

`init-project.sh` fills every `{{PLACEHOLDER}}` and sets up each agent
(`--tools all` by default, or a list such as `--tools claude,codex`):

| Agent | What it reads | What the script does |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` (imports `AGENTS.md`), `.claude/skills/` | Keeps them |
| Codex CLI (and Codex in ChatGPT) | `AGENTS.md`; skills in `.agents/skills/` | Links `.agents/skills` to `.claude/skills` |
| Pi | `AGENTS.md`; skills in `.pi/skills/` | Links `.pi/skills` to `.claude/skills` |
| Gemini CLI | `GEMINI.md` by default | Writes `.gemini/settings.json` so it reads `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md`, `AGENTS.md` | Writes a pointer |
| Cursor | `AGENTS.md`, `.cursor/rules/` | Writes a rule pointing to it |
| Others (Aider, Zed, Amp, Jules, ...) | Usually `AGENTS.md`; otherwise point them to it (Aider: `--read AGENTS.md`) | Nothing needed |

Use `--copy` instead of links on Windows. Then ask your agent to run the
`start-project` skill with your brief, or fill `docs/` by hand. The skills
are plain Markdown, so an agent without skill support can be told "follow
`.claude/skills/close-task-set/SKILL.md`".

### For your user, in every project

```sh
user-level/install-user.sh               # or --tools claude,codex,pi ; --dry-run to see first
```

It appends the working rules between marker lines to `~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md` and `~/.pi/agent/AGENTS.md` (a second run replaces the
block), and copies the skills to `~/.claude/skills`, `~/.codex/skills` and
`~/.pi/agent/skills`, leaving any skill you already have.

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
the forecast, the history and a filterable list. Python 3.11, no
dependencies; English or Brazilian Portuguese (`docs/dashboard/config.toml`).
`--out` writes a page, `--artifact` a fragment for a hosted page such as a
claude.ai Artifact, `--record` stores the day's numbers and changes.
`.github/workflows/dashboard.yml` publishes it with GitHub Pages.

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
