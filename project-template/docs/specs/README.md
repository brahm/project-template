# Specifications

What an item of {{PROJECT_NAME}} must do, written before it is built, when
no reference already says it. A specification here is short: its job is to
turn what the owner asked into sentences a test can check, and to bring
out what nobody said.

## When an item gets a page

| The work | What it needs |
| --- | --- |
| A small fix, or a change with one obvious behaviour | A test that states the behaviour. No page. |
| An item that a reference of [verification.md](../verification.md) defines completely | Its reference case. No page. |
| Anything else | A page here, written by whoever builds the item, before the code. |

The agent writes the page; the owner reads only its last two sections,
the assumptions and the questions.

## The form of a page

One file per item or group of items, named after the inventory row:
`F-012-export-to-pdf.md`. The `note` of the row links to it.

```markdown
# F-012: export to PDF

## Goal
One or two sentences, in the owner's words where they exist: who needs
this, and what changes for them.

## Acceptance criteria
- AC-1. A sentence a test or a comparison can check.
- AC-2. The empty case, the limit and the failure each have their own.

## Out of this item
What a reader might expect and will not find, and the backlog row or the
phase where it lives.

## How it is checked
The tests of each criterion, and the reference when there is one.

## Assumptions
What nobody specified and was settled to keep working, each with its
decision id (D-014, assumed).

## Questions for the owner
Only what belongs to the owner, each with the options and the one
recommended. Empty when there is none.
```

Tests cite the criterion they check (`F-012 AC-2`). When the behaviour
changes, the page changes in the same pull request; a page that no longer
matches the code is deleted or corrected, never left.

## What is usually left out

Go through this list for each item and write down only the lines that
apply. The defaults of the project are in
[engineering.md](../engineering.md); a line is needed only where the item
differs from them or they are silent.

| Area | The questions |
| --- | --- |
| Input | What if it is empty, very large, malformed, repeated, or in another language or encoding? |
| Failure | What does the user see when it fails? What is kept, and what can be tried again or undone? |
| Data | Where is it stored, in what format and version? What happens to data that already exists? What does deleting mean? |
| Security and privacy | Who may do this? Which input is untrusted? Which personal data is touched, and what is logged? |
| Interface | How does it work from the keyboard and a screen reader? What are the empty, loading and failure states? Does long or translated text fit? |
| Performance | What size must it handle, and how long may it take? |
| Compatibility | Which versions of the platform, of files and of interfaces others rely on must keep working? |
| Time and concurrency | What if two happen at once, or one stops halfway? Do time zones or the clock matter? |
| Operation | What is configurable? How does someone learn that it broke? Does it cost money to run? |
| Documentation | Which page of `docs` or of user help changes with it? |
