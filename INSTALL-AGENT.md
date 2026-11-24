# Installing the kit: the procedure for a coding agent

The owner pasted a prompt asking you to install this kit in the folder
you were opened in (the prompt is in [INSTALL.md](INSTALL.md), "From a
prompt"). Do it with `install.sh`, from the copy of the kit you just
cloned, and leave nothing for the owner to do but the two steps that need
their own terminal. Talk to the owner in their language.

Your shell has no terminal: `install.sh` and the scripts it runs ask
nothing and take their defaults, so give every value as an option.

## 1. Look before you change anything

- **The tools.** `git`, `python3` (3.11 or later) and `gh`. If one is
  missing, say how to install it on the owner's system and stop.
- **GitHub.** `gh auth status`. If it is not signed in, or its token
  scopes do not include `workflow`, ask the owner to run, in a terminal
  of their own (not through you, since it is interactive):
  `gh auth login -h github.com -s workflow`. Wait for it.
- **The folder.** Which case it is:

  | What is there | Case |
  | --- | --- |
  | `docs/kit.md` | The kit is already installed: go to "Updating" below |
  | Nothing, or only `.git` without commits, `.claude/settings.local.json`, `.DS_Store` | A new project |
  | A git repository with files | A project under way |
  | Files, but no git repository | A project under way, once the owner agrees to `git init` |

- **The owner's defaults.** The section between the lines
  `agent-project-kit: owner defaults` in `~/.claude/CLAUDE.md`, when it
  is there: owner, languages, time zone, licence, GitHub account.

## 2. Ask once

In one message, each question with the answer you will assume:

- New project: what it is (one line, for `--summary`; the rest of what
  they say is the brief of step 4), the repository name (the folder's),
  public or private (private), and the GitHub account or organisation
  (the signed-in one).
- Project under way: whether `main` may be protected, so that from then
  on it changes only through pull requests whose checks pass (yes).
- Both: values missing from the defaults (owner, languages, time zone,
  licence), and whether to also install the kit's rules and skills for
  their user, for every project (no, unless they ask).

If the owner told you to decide, go on with what you assumed.

## 3. Run the installer

```sh
"$KIT/install.sh" new . --no-user --summary "..." [--public] [--github-owner ORG] \
    [--owner ... --owner-lang ... --dashboard-lang en|pt-BR --repo-lang ... --timezone ... --license ...]
"$KIT/install.sh" existing . --no-user [--no-rules] [the same value options]
```

`$KIT` is your clone. Send the output to a file and read its end. It
pushes the first commit (new project), puts the kit on a branch
`agent-kit` (project under way), saves nothing as a secret, because the
token needs a terminal, and writes the rules of `main`. If it stops,
fix the cause and run the same command again; what is done is kept.
For the user's rules and skills, if wanted:
`"$KIT/user-level/install-user.sh"` with `--owner`, `--owner-lang`,
`--dashboard-lang`, `--repo-lang`, `--timezone`, `--license` and
`--github`.

## 4. Hand over the token, and go on

The automatic review needs the token of the owner's Claude plan. It must
never pass through this conversation: ask the owner to run, in a
terminal of their own, at the root of the project,

```sh
scripts/setup-github.sh
```

which offers to run `claude setup-token` and reads the token without
showing it. If the owner pastes a token in the chat anyway, do not repeat
it or write it anywhere; tell them to make a new one with
`claude setup-token`, since the one they pasted is now in a conversation.

Do not wait for it. Read the project's `AGENTS.md` and follow the
`start-project` skill (`.claude/skills/start-project/SKILL.md`): with the
owner's brief for a new project, or adopting the kit for a project under
way. Then report: what was installed, what you assumed, and the one
command left for the owner, if they have not run it yet.

## Updating

When the kit is already there, run `"$KIT/install.sh" update .`, and if
the project's kit version is older, follow its
`update-from-template` skill with your clone as the template.

Remove your clone of the kit when you are done.
