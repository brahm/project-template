# The Second Brain of {{PROJECT_NAME}}

What the project knows, one note per subject, so that a person or an agent
finds it in seconds instead of asking again or reading the whole
repository. `python3 scripts/brain.py find WORDS` searches it, and the
records it points to, in one command.

## The method

The brain follows the Zettelkasten method (one idea per note, notes linked
to each other) kept the way an LLM wiki is kept: the agent writes and
corrects the notes as it works, an index lists them, and a script checks
them. Everything is plain Markdown in the repository, readable in any
editor, on GitHub or in a tool such as Obsidian, and nothing needs to be
installed.

1. **One subject per note**, named for its subject in lower case with
   hyphens: `payment-provider.md`, `why-the-cache-is-per-user.md`. When a
   note grows a second subject, split it.
2. **The current truth first.** A note opens with a one or two sentence
   summary, the line that starts with `>`. Someone who reads only the
   summary must not be misled.
3. **Rewrite, do not append.** When what is known changes, the note is
   rewritten to say what is true now, and cites what changed it (`D-012`,
   PR #40). The old version stays in git, and the story stays in the
   records.
4. **Point to the records, do not copy them.** A decision, a lesson, a
   backlog row or an inventory row is cited by its id, and
   `scripts/check-docs.py` fails if the id does not exist.
5. **Link the notes** that explain each other, under "Related".
6. **Keep it short.** A note that only repeats a page of `docs` is a link
   in that page instead.

## What goes in, and what stays in its record

A fact that stays true until something changes it is knowledge, and goes
in a note. A fact that is true of one day is a record, and stays in its
register, where the note can point to it.

| Goes in a note | Stays in its record, cited from the note |
| --- | --- |
| How a part works and why it is built that way | The decision itself, its date and its reason: [decisions.md](../decisions.md) and the [project log](../project-log.md) |
| Facts of the domain and of the reference: terms, rules, limits, formats | What was done and when: the [project log](../project-log.md) and [HISTORY.md](../../HISTORY.md) |
| Outside systems: services, accounts, APIs, their limits and quirks (never a secret) | Dates, estimates and changes of schedule: the [roadmap](../roadmap.md) and the [dashboard](../dashboard/README.md) |
| The cause of a problem once it is found, and how to recognise it | The status of an item: the [inventory](../inventory/README.md) |
| How to do something that is done now and then but is not worth a skill | Work left undone: the [backlog](../backlog/README.md) |
| What the owner explained about the context, the users or their preferences, when it is not a decision | Mistakes and their guards: [lessons.md](../lessons.md) |
| Where something is, when its place is not obvious | The rules: [AGENTS.md](../../AGENTS.md) |

So a decision is in the brain only as the knowledge it produced. The
note on the payment provider says which provider is used and how it
behaves, and cites `D-007`; the date of the choice, the alternatives and
the reason are in the decision log. A changed deadline is never a note:
the roadmap and the dashboard history keep it.

## When it is written

- **When something is learned** that the next session will need, at
  once, by the `update-brain` skill. In Claude Code a hook reminds the
  agent when a piece of work changed files and no note.
- **When a set of tasks closes**, `close-task-set` asks whether the
  notes of the subjects touched still say the truth.
- **When the project starts**, `start-project` writes the
  [glossary](glossary.md) and a note per subject of the brief.

## A note

```markdown
# Payment provider

> We charge cards through ExamplePay's hosted checkout; we never see card numbers (D-007).

Tags: payments, outside-service
Updated: 2026-11-24

## What we know

Plain sentences: how it works, its limits, what to watch for.

## Why it is so

The decision or the cause, by id: D-007, L-003, PR #40.

## Related

- [Refunds](refunds.md)
```

`Tags` are free words, separated by commas. `Updated` is the date the
note was last made true.

## Notes

`python3 scripts/brain.py index` writes this table from the notes;
`scripts/check-all.sh` fails while it is out of date.

<!-- brain:index begin -->
| Note | Summary | Tags | Updated |
| --- | --- | --- | --- |
| [Glossary](glossary.md) | The words of {{PROJECT_NAME}}: what each means here, and the word not to use for it. | vocabulary | {{TODAY}} |
<!-- brain:index end -->
