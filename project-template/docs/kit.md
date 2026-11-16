# The agent kit of this project

{{PROJECT_NAME}} was made from the agent project kit: the rules of
[AGENTS.md](../AGENTS.md), the skills, the scripts and the records they
keep. This page says how the pieces fit, how they are fitted to the
project, and how the project and the template stay in step.

| | |
| --- | --- |
| Template | <https://github.com/brahm/project-template>, folder `project-template` |
| Kit version | 1.1.0 |

## How the pieces fit

| Piece | What it does | When it runs |
| --- | --- | --- |
| `AGENTS.md` | The rules, and the moments at which each skill applies | Read by every agent at the start of a session |
| `.claude/skills/` | One short procedure per moment: starting, planning, specifying, deferring, deciding, validating, closing, reporting, learning | Opened by the agent when the moment comes; the owner does not invoke them |
| `.claude/settings.json` | Runs `scripts/status.py` when a Claude Code session starts, and lets the project's own check scripts run without asking | By Claude Code |
| `scripts/status.py` | The state of the project in a few lines, so that an agent does not read five pages to learn it | At the start of a session |
| `scripts/check-all.sh` | Every check: the language's, the backlog, the dashboard sources, the docs, the records, the licences | Once before a set of tasks ends, and in CI |
| `scripts/check-docs.py` | Links between pages resolve, ids cited exist, the decision log is well formed, no placeholder is left | In `check-all.sh` |
| `scripts/check-records.py` | The dashboard was recorded, and a change comes with its HISTORY line and its project log entry | In `check-all.sh` and on pull requests |
| `docs/` | The goals, decisions, plan, standards and records | Opened when a task touches them |

What a rule can say, a check says better: when something keeps being
forgotten, it becomes a check ([lessons.md](lessons.md)).

## The files that come from the kit

`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `.claude/`, `scripts/`,
`.github/`, and in `docs`: `README.md`, `engineering.md`,
`writing-style.md`, `kit.md`, and the `README.md` of `backlog`,
`dashboard`, `inventory` and `specs`. The other pages of `docs` and
`HISTORY.md` hold the project's own content and are never replaced by the
template's.

## Fitting the skills to the project

The skills are the project's own from the first day: an agent edits them
when the project calls something by another name, and adds one when a
procedure will be repeated (how to run the application, how to make a
reference case, how to release). A skill here is written this way:

- A folder `.claude/skills/NAME/` with a `SKILL.md`. Its header gives the
  `name` and a `description` that starts with "Use when" and names the
  moment, because the description is what an agent reads to decide.
- One moment per skill, as numbered steps, in about sixty lines at most. Longer
  material goes in a file beside it that the skill points to.
- It says what to do at that moment and where the result is recorded. It
  does not repeat the rules of AGENTS.md, and it leaves the how to the
  agent.
- A new skill gets a row in rule 2 of AGENTS.md, so that every agent
  knows its moment.

## Outside skills

A skill written by someone else is added only for a need the project has
now, never as a collection. It is a set of instructions an agent will
follow, so it is treated as code from a stranger:

1. **Read it whole**, with its scripts, before adding it. Do not add one
   that fetches or runs something you cannot read, or that tells the
   agent to ignore the rules of the project.
2. **Check the licence.** Copy the skill only if its licence allows it;
   keep its licence file with it, put the licence text in `LICENSES/`,
   and add a table for its folder to `REUSE.toml` with its copyright and
   SPDX identifier.
3. **Take the one skill**, at a named commit or version, and record it in
   the table below.
4. **Tell the owner** in the report: which skill, from where, and why.

Where it is worth looking:

| Source | Licence | Worth taking when |
| --- | --- | --- |
| [anthropics/skills](https://github.com/anthropics/skills) | Stated per skill in its `LICENSE.txt`; many are Apache-2.0. Its document skills (docx, pdf, pptx, xlsx) are source-available and are not copied | The project has a web interface to test in a browser (`webapp-testing`), builds an MCP server (`mcp-builder`), or needs an interface with a design of its own (`frontend-design`) |
| [obra/superpowers](https://github.com/obra/superpowers) | MIT | One of its skills answers a failure that repeats in this project, for example `systematic-debugging` after a bug was fixed twice. Take that skill, not the method: this kit leaves the method to the agent |
| The agent's own commands (Claude Code: `/code-review`, `/security-review`) | Part of the tool | Reviewing a change before it closes; nothing to install |

Licences change: read the licence file of the version you take.

### Outside skills in this project

| Skill | Source and version | Licence | Why |
| --- | --- | --- | --- |

## Keeping in step with the template

The template improves as its projects learn. The `update-from-template`
skill brings its newer rules, skills and scripts into this project
without losing what was fitted here, and takes the lessons of this
project marked `proposed` in [lessons.md](lessons.md) the other way. It
runs when the owner says the template changed and when a phase closes.
After an update, the kit version above is set to the template's.
