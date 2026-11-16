---
name: validate-against-reference
description: Use before marking an item done when its behaviour is defined by a reference (a specification, an existing product, an older version). Checks it against the reference named in docs/verification.md and records the result.
---

# Validate against the reference

"It looks right" is not a check. An item is done only when it was compared
with its reference and the result is recorded.

1. **Find the reference** for the item in `docs/verification.md`: which
   specification or product, which version, on which machine or
   environment (CI, the owner's computer, a virtual machine), and which
   decision says so when references disagree.
2. **Make or find the reference case**: an input made with the reference
   and the output it gives, named after the inventory row. Never commit
   material whose licence forbids it.
3. **Compare.** Automatically where possible (a test that cites the row
   id); by eye otherwise, with screenshots or documents side by side on
   the named machine. If you cannot reach the reference (machine off, no
   access), do not mark the item done: record it with `defer-work` and say
   so.
4. **Write the parity document** when the check is by eye: what was
   compared, version and machine, date, what matched, what did not, and
   the row id. Keep it where `docs/verification.md` says.
5. **Record the result** in the inventory row: `status` `Done` and
   `review` `-` only if it matched; otherwise `Partial` with what differs
   in `note`, or a reason in `review`.
6. **Report** what was checked, against what, and what did not match.

An item with a page in `docs/specs` is checked the same way against its
acceptance criteria: each one has a test that passes, or the item is not
done.
