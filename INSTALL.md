# Installing and updating the kit

(Português: [INSTALACAO.md](INSTALACAO.md).)

This manual covers the three cases: a new project, a project already under
way, and keeping both the kit and your projects up to date. The simplest
way is a prompt to your coding agent; underneath, everything is done by
one script, `install.sh`, on your own computer.

## What you need

- `bash`, `git` and Python 3.11 or later. On Windows, use Git Bash or WSL.
- The GitHub CLI, [`gh`](https://cli.github.com), for the GitHub part (the
  repository, the secret and the rules of `main`). If it is not signed in,
  the installer runs `gh auth login` for you, and adds the `workflow`
  permission that pushing the kit's workflows needs.
- Claude Code, for `claude setup-token`, if you want the automatic review
  of each pull request to run on your Claude Pro or Max plan. Without it,
  the installer asks you to paste a token made on another computer, or
  skips that step.
- Optional: [`reuse`](https://reuse.software) for the licence check
  (`pipx install reuse`).

## From a prompt (the simplest)

Open Claude Code (or another coding agent) in the folder of the project:
an empty folder for a new project, or the project you already have. Paste:

```text
Install the agent project kit in this folder. Clone
https://github.com/brahm/project-template into a temporary folder and
follow its INSTALL-AGENT.md. What I want to build: ...
```

(For a project under way, leave out the last sentence.) The agent checks
the tools and your GitHub sign-in, sees whether the folder is a new
project or one under way, asks once for what it cannot work out, runs
`install.sh` with every value, and then starts the project from your
brief, or adopts the kit in your code, in the same conversation. To
update, paste the same prompt in a project that has the kit: it runs
`install.sh update` and the `update-from-template` skill.

Two steps stay with you, in a terminal of your own, because they are
interactive and the agent cannot type into them:

- `gh auth login -h github.com -s workflow`, only if `gh` is not signed in
  (the agent tells you).
- `scripts/setup-github.sh`, at the root of the project, to save the token
  of your Claude plan for the automatic review. It offers to run `claude
  setup-token` and reads the token without showing it, so the token never
  passes through the conversation. Do not paste it in the chat.

The procedure the agent follows is [INSTALL-AGENT.md](INSTALL-AGENT.md).
The sections below are the same steps by hand.

## Getting the installer

Either keep a copy of the kit, which you will update with `git pull`:

```sh
git clone https://github.com/brahm/project-template agent-kit
agent-kit/install.sh --help
```

or run it without a copy; it fetches the kit to a temporary folder first:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/brahm/project-template/main/install.sh) --help
```

Below, `install.sh` stands for either form.

## A new project

```sh
install.sh new my-project
```

In order, it:

1. Copies the template to the folder `my-project` and runs
   `init-project.sh` in it. The name, owner, languages, time zone and
   licence come from your defaults (see "Your user" below) or the options
   you give; whatever is still missing is asked.
2. Makes the first commit, on `main`.
3. Creates the GitHub repository `your-account/my-project`, private, and
   pushes `main` to it.
4. Turns the automatic review on (`scripts/setup-github.sh`, below): it
   offers to run `claude setup-token`, asks you to paste the token
   without showing it, saves it as the secret `CLAUDE_CODE_OAUTH_TOKEN`,
   and protects `main`.
5. Offers to install the kit's rules and skills for your user, if they are
   not there yet.

Then open your agent in the folder and say what you want to build:

```sh
cd my-project && claude
```

It sees that the project has not been started and plans it with you (the
`start-project` skill).

Useful options: `--public` for a public repository, `--github-owner ORG`
to create it under an organisation, `--no-github` to stay on your computer,
`--summary "a tool that ..."`, `--tools claude,codex` for the agents you
use, `--copy` on Windows. `install.sh --help` lists them all.

If something fails halfway (no network, a typo in the token), fix it and
run the same command again: the steps already done are kept.

## A project under way

In the folder of the project (a git repository), or naming it:

```sh
install.sh existing            # or: install.sh existing path/to/project
```

It never overwrites a file of yours:

| Your file | What the installer does |
| --- | --- |
| Does not exist | Adds the kit's |
| `AGENTS.md` | Adds the kit's rules at its end, between marker lines |
| `CLAUDE.md` | Adds the import of `AGENTS.md`, if it has none |
| `.claude/settings.json` | Adds the kit's permissions and hooks to yours |
| `.gitignore`, `.github/CODEOWNERS` | Adds the lines it lacks |
| A workflow with the kit's name (`checks.yml`) | Adds the kit's as `kit-checks.yml` |
| Any other file (`README.md`, `docs/README.md`, ...) | Keeps yours, and lists it |

When your working tree is clean, the kit goes on a new branch,
`agent-kit`; nothing is committed. If the repository is on GitHub, the
GitHub part runs too; it asks before protecting `main`, because from then
on `main` changes only through pull requests.

Then open your agent in the project and say "adopt the kit in this
project". It reads your code and README as the brief, writes the goals,
decisions, inventory and roadmap from what exists, merges the files the
installer kept with the kit's, makes the checks pass on your code, and
opens a pull request.

## The GitHub part alone

For a project made otherwise, or to replace the token when it expires
(about a year):

```sh
install.sh github                       # in the project: what is missing
scripts/setup-github.sh --replace-token # in a project of the kit: a new token
```

What it sets on the repository:

- The secret `CLAUDE_CODE_OAUTH_TOKEN`. The token goes from your
  terminal to `gh secret set` through a pipe: never to a file, never on a
  command line. A secret that exists is kept unless you pass
  `--replace-token`.
- The ruleset `agent-kit: main` on the default branch: changes arrive by
  pull request; the checks `Review` and those of `checks.yml` must pass;
  a change to `.github/` or to the review's script waits for the owner
  (Code Owners). No approval count is asked for, because a personal
  account cannot approve its own pull request; when a change waits for
  you as Code Owner, you merge it with the bypass, which works only
  through a pull request, never by a direct push.

GitHub Free has no rulesets for private repositories. The script then
says so and goes on: the review still comments on every pull request, but
cannot stop a merge. Make the repository public, or move to GitHub Pro,
and run it again.

## Your user

```sh
install.sh user
```

Adds the kit's working rules to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`
and `~/.pi/agent/AGENTS.md` (between marker lines), copies the skills, and
asks once for your defaults for new projects: your name, languages, time
zone, licence and GitHub account. `install.sh new` and `existing` use
those defaults, so they ask less. It never overwrites a file of yours;
edit the defaults where it wrote them. `install.sh user --help` lists the
options.

## Update

```sh
install.sh update                       # in a project, or: install.sh update path/to/project
```

1. Updates your copy of the kit (`git pull`). Run with `bash <(curl ...)`,
   the kit is already the newest.
2. If the kit is installed for your user, replaces its rules and its
   skills with the new version, keeping your defaults.
3. In a project, compares its kit version (`docs/kit.md`) with the
   newest, and says what to do.

The project itself is updated by its agent: say "update the kit". It reads
the kit's `HISTORY.md` from the project's version on, takes each change
without losing what was fitted to the project (the `update-from-template`
skill), runs the checks and opens a pull request.

## Starting from GitHub's "Use this template"

If you prefer the button, make a repository of the template folder once:

```sh
cp -R agent-kit/project-template my-template && cd my-template
git init -b main && git add -A && git commit -m "Agent project template"
gh repo create my-template --private --source . --push
```

and mark it "Template repository" in its settings. A project made with the
button is filled by the agent when you first open it; run
`scripts/setup-github.sh` in it to turn the review on. Do not use the
button on the kit's repository itself: that copies the whole kit.
