---
name: report-to-owner
description: Use when writing any report, status message, pull request description or summary for the project owner. Applies docs/writing-style.md and makes sure nothing assumed, left undone or moved is hidden.
---

# Report to the owner

The owner reads the report quickly, often hours later. Write it in the
owner's language (see `AGENTS.md`) and by `docs/writing-style.md`.

1. **Outcome first**, in one or two sentences: what is done, with the link
   (pull request, page, file).
2. **What it depends on**: what was checked and how (tests, reference),
   and anything that is a guess. Never claim a check you did not run; if
   tests fail, say which and show the output.
3. **Decisions you assumed**, one line each: "Assumed: <decision>
   (D-nnn), because <reason>." The owner confirms or replaces them; leave
   the line out when there is none.
4. **Left undone, explicitly**, one line per item: "Left undone: <item>
   (B-nnn), moved to phase <phase>, because <reason>." Write "Nothing was
   left undone" when that is true.
5. **Decisions needed**, if any: the question, the options, your
   recommendation and why. One question at a time.
6. **Next step**, at most one sentence.

Style: full sentences, plain words, no arrow or dash chains, absolute
dates, numbers with their date, ids cited (F-001, D-003, B-007, #42).
Short. No replay of the work behind the result.
