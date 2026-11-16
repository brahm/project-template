# Writing style

How documentation, comments, commit messages, history lines and reports to
the owner are written in {{PROJECT_NAME}}. The aim is text that a person
reads once and understands, and that is still true a month later.

## Voice

- **Plain words, full sentences.** Write as you would explain the thing to
  a capable colleague who was not in the room. No slogans, no hype, no
  marketing adjectives ("powerful", "seamless", "blazing").
- **Say what it does, in the words of the domain.** A paragraph, an
  invoice, a build; not a struct, a handler, a callback, unless the reader
  needs those.
- **Active and concrete.** "The script stops when the phase has open
  rows", not "Execution may be halted in certain circumstances".
- **The reason, not only the fact.** A decision, a rule or a comment says
  why. The what is usually visible already.
- **Honest.** Say what was not done, what failed, and what is a guess.
  Never write that something was checked when it was not.
- **Neutral about people.** Use the name or "they" unless someone's
  pronouns are known.

## Form

- **Lead with the result or the ask.** The first sentence of a report, a
  pull request or a log entry says what happened or what is needed.
- **Short paragraphs, short lists.** A list is for things that are really
  parallel; an argument is prose.
- **No dash chains and no arrow chains** ("A → B → C"). Write the sentence.
- **Headings in sentence case**, short, and saying what the section holds.
- **Dates are absolute** (2026-11-16 or 16 November 2026), never
  "yesterday" or "last week". **Numbers are dated**: a count without its
  date is wrong the next day.
- **Ids are cited** where they explain something: rows (`F-104`),
  decisions (`D-003`), backlog items (`B-007`), pull requests (`#42`).
- **Links instead of repetition.** Say a thing once, in its page, and link
  to it.

## By kind of text

| Text | Form |
| --- | --- |
| Code comment | Full sentences; what the file or item is for, how a non-obvious body works, and why. No commented-out code, no history. |
| Commit message | Imperative subject of at most 72 characters, then what changed and why. |
| Pull request | What it does, the rows it covers, how it was tested, what it left undone and where it went. |
| HISTORY line | `Added:`, `Changed:`, `Fixed:` or `Removed:`, one change in plain words for a visitor, with the pull request. |
| Project log | A dated entry: what was done, each decision with its reason, what followed, what was left undone. |
| Report to the owner | The outcome first; then what it depends on; then what was left undone, naming each item and the phase it moved to; then, at most once, a suggested next step. In {{OWNER_LANGUAGE}}. |

## Words to avoid

Vague intensifiers (very, really, extremely), filler openings ("It is
worth noting that", "In order to"), hedges stacked on hedges, and jargon a
newcomer would have to look up when a plain word exists.
