# Engineering standards

The defaults of design, code, tests and safety in {{PROJECT_NAME}}. They
answer the questions the owner should not have to answer again in every
task. An agent applies them without being told; where a task needs
something else, that is written in its [specification](specs/README.md).
Changing a default of this page is a [decision](decisions.md).

When the project starts, this page is fitted to it: the sections that do
not apply are deleted, and the conventions of its technology (formatter,
linter, test runner, layout of the source tree, the idiom for errors) are
added under [The technology of this project](#the-technology-of-this-project).

## Design

1. **The simplest design that meets the acceptance criteria.** Build what
   the item needs now. Do not add an option, a layer or a parameter for a
   need nobody has stated; wait for the third similar case before you
   make an abstraction.
2. **Logic apart from input and output.** The rules of the domain are
   plain functions and types that touch no file, network, clock or
   screen. A thin outer layer reads, calls them and writes. The logic is
   then tested without setting anything up.
3. **Dependencies point inwards.** The outer parts know the inner ones,
   never the reverse, by the boundaries of
   [architecture.md](architecture.md). What varies or cannot be
   controlled in a test (time, randomness, the network, the file system,
   a vendor) comes in through an interface.
4. **Check data once, at the edge.** Turn untrusted input into a type
   that cannot hold an invalid value, and let the inner code rely on it.
5. **One source for each fact.** A value, a rule or a sentence of
   documentation lives in one place, and the rest is derived or links to
   it.
6. **A named pattern only when it removes a problem you have.** When you
   use one, name it in the module comment so the next reader recognises
   it.

   | The problem | The usual answer |
   | --- | --- |
   | An action the user must be able to undo or repeat | Command: each change is an object that can apply and revert itself |
   | Several ways to do one thing, chosen at run time | Strategy: one interface, one implementation per way |
   | A library or service whose shape should not spread | Adapter: one module translates, and the rest sees the project's own types |
   | Behaviour that depends on a state with rules for changing it | An explicit state machine: the states and transitions as data |
   | Parts that must react to a change without knowing each other | Events: the source announces, the listeners subscribe |
   | Stored data read and written from many places | Repository: one module owns the storage and its format |
   | Building a value that has many optional parts | Builder, or a plain record with defaults |

## Code

- Names come from the domain and say what a thing is for. A function
  does one thing and fits on a screen.
- The formatter and the linter decide the style; their warnings are
  fixed, not silenced. New code looks like the code beside it.
- No dead code and no commented-out code. A `TODO`, `FIXME`, `XXX` or
  `HACK` cites its open backlog row, `TODO(B-012)`, and goes away in the
  change that closes the row. `scripts/check-backlog.py` checks both, so
  that no agent follows a note about work that is finished.
- A change does what its task says. A clean-up or a bug noticed on the
  way is a backlog row and a line in the report, not part of the change,
  unless the task needs it.

## Failures

- A failure is handled where something can be done about it, and carries
  what is needed to understand it: what was being done, with what. It is
  never swallowed.
- Nothing a user can type, open or send makes the program crash or lose
  their work.
- A message to the user says what happened and what they can do, in
  their words.

## Tests

- A test states a behaviour, not how the code is written: it should
  survive a rewrite that keeps the behaviour. Each acceptance criterion
  has at least one test that cites it (`F-012 AC-3`).
- Most tests exercise the logic directly and run in milliseconds. A few
  cross the edges (files, network, interface) to show the parts fit.
- Tests do not depend on the time of day, the network, random values or
  each other.
- A bug is fixed by a test that fails because of it, then by the fix.
  Find the cause before changing code; a fix that only hides the symptom
  is recorded as [left undone](backlog/README.md).
- Code that reads what a stranger wrote (a parser, an importer) is also
  tested with broken and random input.

## Security and privacy

- No secret enters the repository: keys, tokens and passwords come from
  the environment, and `.env` files are ignored by git. A secret
  committed by mistake is revoked, not only deleted.
- Everything from outside the program is untrusted until checked: files,
  form fields, network answers, command-line arguments, and the text an
  AI model returns.
- Queries and shell commands are built with parameters, never by joining
  strings. Output is escaped for where it goes.
- The program asks for the least access it needs, and keeps the least
  personal data it can. Personal data is not written to logs.
- Sending data to another service, collecting usage data and adding a
  login are decisions of the owner.

## Dependencies

- Prefer the standard library and the platform. A new dependency needs a
  reason in the pull request: what it saves, that it is maintained, and
  that its licence fits the project's.
- Versions are pinned and the lock file is committed. An update is its
  own change, with the tests run.

## Data and compatibility

- A stored format, a schema and a public interface have a version. A
  change to one comes with the migration of what already exists, and
  with a test that opens data of the previous version.
- Nothing destroys the user's data without a way back: a copy, an undo,
  or a confirmation that says what will be lost.

## Performance

- Decide the size the item must handle and the time it may take when
  that matters, and write both in its specification. Measure before
  optimising, and keep the measurement as a test or a note.

## The interface

Delete this section if the project has none.

- Everything works from the keyboard and is named for a screen reader.
  Colour is never the only signal, and the text keeps its contrast.
- Every view has its empty, loading and failure states.
- Text shown to the user lives apart from the code, so that it can be
  reviewed and translated.

## Git and pull requests

- One branch and one pull request per set of tasks, small enough to read
  in one sitting. A large piece of work is split so that each part
  leaves the project working.
- A commit is one logical change with a message by
  [writing-style.md](writing-style.md). History that others have seen is
  not rewritten.
- The main branch always passes `scripts/check-all.sh`.

## Reviewing a change

Before the records of a set of tasks, read the whole diff once as someone
who did not write it:

1. Does it do what the task and its acceptance criteria say, and nothing
   else?
2. Is each criterion tested, including the empty, the limit and the
   failure cases?
3. Is there a simpler way that you passed over?
4. Are the boundaries of the architecture kept, and is each new
   dependency justified?
5. Could untrusted input reach a query, a path, a command or the screen
   unchecked? Is any secret or personal data in the code, the tests or
   the logs?
6. Do the comments and the pages of `docs` still say what the code does?
7. Is anything left that was only for debugging?

Where the agent has a review command of its own (Claude Code:
`/code-review`, and `/security-review` for a change that touches access,
files or the network), run it on the diff as well.

## The technology of this project

Filled in when the project starts: the language and its version, the
formatter and linter with their commands, the test runner, the layout of
the source tree, and the idioms the code follows.
