# Goals of {{PROJECT_NAME}}

*Set on YYYY-MM-DD. Each rule points to its entry in
[decisions.md](decisions.md).*

{{PROJECT_NAME}} is {{PROJECT_SUMMARY}}.

## The target

Say in one paragraph what "done" means, measurably: parity with a
reference, a set of user stories, a specification. The inventory turns this
paragraph into rows.

## The rules of the target

1. **In scope:** what counts, and which reference sets the behaviour (D-001).
2. **Out of scope but kept on record:** what is not built, with the reason.
   Such rows stay in the inventory with their mark and reason, and the
   architecture must not rule them out (D-002).
3. **Not applicable:** what has no meaning on this platform, unless the
   platform has an equivalent (D-003).
4. **A new version of the reference** is a review of the inventory, not a
   change of target in the middle of a phase.

## Verification

What the work is checked against, and where: see
[verification.md](verification.md).

## Technology and distribution

Languages, frameworks, minimum versions, how it is shipped.

## Documentation and code

The project is documented for outside contributors, human or agent:
architecture, decisions, roadmap and diagrams. Every source file is
commented so that a person understands how it works by reading it.

## What is not done

Whatever a set of tasks leaves undone is recorded with its reason in
[backlog](backlog/README.md), and the backlog of a phase is worked at the
end of that phase.
