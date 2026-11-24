# Working on the kit

This repository is the agent project kit: a project template
(`project-template/`), the rules and installer for a user (`user-level/`),
and the text and skill zips for the chat apps (`desktop/`). `README.md`
describes it in English and `LEIA-ME.md` in Brazilian Portuguese.

`CLAUDE.md` only points here.

## What is the product, and what are the rules

Everything under `project-template/` is the product. Its `AGENTS.md`, its
`CLAUDE.md`, its skills and its session hook apply in a project made from
it, not here. In this repository, never run `init-project.sh`, never follow
`start-project`, and read "this project has not been started" as text you
are editing.

## Changing the kit

1. **Keep the kit light.** It exists so that an agent keeps its own
   judgement: a rule names what must not be forgotten and leaves the how
   to the agent. Before adding a rule, try a check
   (`project-template/scripts/`), then a line in the skill of that
   moment, then a sharper wording of a rule that exists. The template's
   `AGENTS.md` is read at the start of every session of every project, so
   every line there is paid for each time.
2. **One source, several copies.** The rules live in
   `project-template/AGENTS.md`. `user-level/AGENTS.global.md` and
   `desktop/project-instructions.md` restate them for places without a
   repository, and the tables of `README.md` and `LEIA-ME.md` list them
   and the skills. A change to a rule or a skill changes all of these in
   the same pull request.
3. **Run `tools/build-kit.py`** after changing a skill or the template's
   `review.yml`: it rebuilds the zips of `desktop/claude-skills/` and the
   kit's own `.github/workflows/review.yml`.
4. **Run `tools/test-kit.sh`** before pushing. It makes a project from the
   template in a temporary folder, runs its checks, its state report and
   its dashboard, tries each guard on the mistake it exists for, and
   installs the user-level files in a temporary home. The CI runs the
   same script.
5. **Record the change**: a line in `HISTORY.md`, and a new kit version
   there and in `project-template/docs/kit.md` when the template changed.
   Projects read that file to learn what to take
   (`update-from-template`).
6. **Change `main` through a pull request.**
7. Everything is written in English by `project-template/docs/writing-style.md`,
   except `LEIA-ME.md`.

## Starting a new project from the template

When the owner asks for a new project: copy `project-template/` into the
new repository (or create it on GitHub from a template repository made of
that folder), open it, and follow its `AGENTS.md`. It says the project has
not been started and sends you to `start-project`, which does the rest
with the owner's brief. The owner does not have to name a skill.

If a new repository was made as a copy of this whole repository, the
project is the content of `project-template/`. Confirm with the owner
that the repository is a new project and not the kit; then, in its first
commit, move that content to the root and remove the kit's other files.
