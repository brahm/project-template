---
name: update-from-template
description: Use when the owner says the template changed, when a phase closes, or when a lesson of this project is worth taking to the template. Brings the template's newer rules, skills and scripts into the project without losing what was fitted to it, and takes the project's proposed lessons the other way.
---

# Keep the project and the template in step

`docs/kit.md` names the template this project was made from, the version
of the kit it has, and the files that come from the kit.

## Bringing the template's changes in

1. **Get the template**: a shallow clone of the address in `docs/kit.md`
   into a temporary folder, or the local copy the owner points to. If it
   cannot be reached, say so in one line and stop.
2. **Read its `HISTORY.md`** from this project's kit version onwards. If
   there is nothing newer, say so in one line and stop.
3. **Take each change.** Compare the template's file with the project's,
   for the files `docs/kit.md` lists as coming from the kit. A file the
   project never changed takes the template's version. A file that was
   fitted to the project (by `start-project` or by a lesson) is merged by
   hand, keeping what was fitted. The project's own pages are never
   replaced. A new rule that conflicts with a decision of the project is
   a question for the owner.
4. **Check and record**: run `scripts/check-all.sh`, set the kit version
   in `docs/kit.md`, and add a HISTORY line (`Changed: Updated the agent
   kit to version X`). Report what came in, and what you left out and why.

## Taking lessons to the template

1. **List the rows** of `docs/lessons.md` with the status `proposed`.
2. **Write each one as it would read in the template**: the change to
   the rule, the skill or the check, in general words, without this
   project's names or subject.
3. **Send it.** With write access to the template's repository, open one
   pull request there with the changes, a line in its `HISTORY.md`, and
   its tests run. Without it, give the owner the text to apply. A pull
   request to another repository is opened only when the owner asked for
   it or agreed to it.
4. **Mark the rows** `in template` with the pull request once it is
   merged.
