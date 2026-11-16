---
name: capture-lesson
description: Use when the owner corrects you or has to repeat an instruction, when a check or a review catches what a rule should have prevented, when the same mistake happens twice, or when work is redone because something was not specified. Records the lesson in docs/lessons.md and turns it into a guard, so that the owner never has to say it again.
---

# Turn a lesson into a guard

The rules of this project came from failures the owner caught. Keep that
going yourself: the owner should not have to write the rule.

1. **Fix what went wrong** first, or record it with `defer-work`.
2. **Find the cause.** Was there no rule? Was the rule unclear? Was it
   clear and not applied? Was something never specified? A rule that was
   not applied is not fixed by another rule: it needs a check, or a line
   in the skill that runs at that moment.
3. **Choose the cheapest guard that would have caught it**, in the order
   of `docs/lessons.md`: a check that `scripts/check-all.sh` runs; a line
   in a skill; a sharper wording of an existing rule of `AGENTS.md`; a
   new rule only as the last resort. A default of design or code goes in
   `docs/engineering.md`.
4. **Make the guard in the same change**, and show that it works: the
   new check fails on the old mistake.
5. **Add the row** to `docs/lessons.md` with the next free `L-nnn`: what
   went wrong, the cause, the guard and where it is, status `guarded`.
   If you cannot make the guard now, the status is `open` and the row
   comes back when the phase closes.
6. **Would it help any project?** If the lesson is not about this
   project's subject, set the status to `proposed`: it is worth taking
   to the template (`update-from-template`).
7. **Tell the owner** in the report, in one line: what went wrong, and
   what now prevents it.

Keep `AGENTS.md` short. If a rule grows past a few lines, move its detail
to a page of `docs` or to a skill, and leave the pointer.
