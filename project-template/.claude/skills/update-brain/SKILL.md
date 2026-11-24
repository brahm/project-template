---
name: update-brain
description: Use when you learn something the next session will need (how a part works, a fact of the domain or of an outside service, the cause of a problem, context the owner gave), when the hook says the work changed files and no note, and when a set of tasks closes. Writes it in the note of its subject in docs/brain, citing the records instead of copying them.
---

# Keep the Second Brain true

`docs/brain/README.md` holds the method and says what goes in a note and
what stays in its record. Write as you work, not at the end: what is not
written when it is learned is asked again later.

1. **Is it knowledge?** It must stay true until something changes it,
   and someone will need it again. A decision, a date, an estimate, a
   status, work left undone and a mistake have their own records
   (`record-decision`, the roadmap and dashboard, the inventory,
   `defer-work`, `capture-lesson`): write them there, and here only the
   lasting knowledge they produced, citing the id. A secret is never
   written anywhere in the repository. If nothing lasting was learned,
   stop here.
2. **Find its note**: `python3 scripts/brain.py find WORDS`. Change the
   note of that subject rather than making a second one.
3. **Write it** in `docs/brain/NAME.md`, named for the subject in lower
   case with hyphens, in the form of the README: title, the summary line
   (`>`) that says the current truth, `Tags`, `Updated` with today's
   date, then what is known, why (with ids: `D-nnn`, `L-nnn`, `B-nnn`,
   rows, pull requests), and related notes.
4. **Rewrite what became false.** When the new fact replaces an old
   one, rewrite the summary and the text to the truth of today and cite
   what changed it. Do not leave both versions; git keeps the old one.
5. **Link it**: from the related notes, and from the page of `docs` or
   the comment in the code where a reader would look for it.
6. **Index and check**: `python3 scripts/brain.py index`, then
   `python3 scripts/brain.py check`.
7. **Tell the owner** only when the note changes what they believed (a
   cause found, a limit of a service); otherwise the change is enough.
