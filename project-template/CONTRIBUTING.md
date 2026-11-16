# Contributing to {{PROJECT_NAME}}

Thank you for looking. Read [docs/README.md](docs/README.md) first: it
points to the goals, the architecture and the roadmap. Coding agents follow
the same rules, stated for them in [AGENTS.md](AGENTS.md).

## Build and test

```sh
# How to build and run the project: fill in.
scripts/check-all.sh          # every check the CI runs
```

While you work, run the tests of what you changed; run
`scripts/check-all.sh` once before you send the change.

## What a change needs

1. **A row to point to.** Work belongs to a row of the
   [inventory](docs/inventory/README.md). Name the rows in the pull request
   and in the tests.
2. **Tests.** Engine code has unit tests; behaviour that a reference defines
   is compared with a reference case ([docs/verification.md](docs/verification.md));
   the interface is tested the way the docs describe.
3. **The architecture kept.** See [docs/architecture.md](docs/architecture.md).
4. **Extensions documented.** Anything that extends a standard (a format,
   a protocol, a component library) is documented in the same change.
5. **Nothing dropped silently.** What you meant to do and did not gets a
   row in [docs/backlog/deferred.tsv](docs/backlog/README.md) in the same
   pull request.
6. **Licenses.** Every file has an SPDX header or is covered by
   `REUSE.toml`. Nothing whose licence forbids it enters the repository.

## Comments

The standard is that a person understands how a file works by reading that
file.

- **Each file starts with a module comment**: what the file is for, the
  main types or functions in it, and how they fit together. If the file
  implements part of a larger design, it links the page of `docs` that
  explains the design.
- **Each public item has a doc comment** that says what it does and what
  its arguments and result mean, in the words of the domain, not of the
  implementation.
- **Each function whose body is not obvious says how it works**: the steps,
  the invariant it keeps, why this way and not the simpler one. A comment
  explains the reason; the code already says what.
- **Rows and decisions are cited by id** where they explain a behaviour:
  `(F-104)`, `(D-003)`.
- **When understanding a function needs more than a comment can hold**,
  the comment points to the page and section of `docs`.
- Comments are full sentences in {{REPO_LANGUAGE}}. No commented-out code,
  and no notes about the history of a change: that belongs in the commit
  message.

Where the language allows it, the CI builds the documentation with
warnings as errors, so a public item without a doc comment fails.

## Commits and pull requests

A commit message says what changed and why, in the imperative, with a
subject of at most 72 characters. A pull request names the inventory rows
it covers, says how it was tested, and lists what it left undone (the
[template](.github/pull_request_template.md) asks for each).
