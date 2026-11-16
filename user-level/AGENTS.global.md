<!-- agent-project-kit: working rules, begin -->
# Working rules (all projects)

These rules apply in every project. When a project has its own AGENTS.md,
follow it as well; where the two differ, the project wins. They name what
must not be forgotten; inside them, how to reach the goal is yours to
organise.

1. **Prioritize before executing.** List what the task needs, order it
   (what the owner asked first, what unblocks other work, what carries the
   most risk), state the order, then work through it.
2. **Consult before conflicting.** Check earlier decisions and
   instructions of the owner. When a task conflicts with one, stop and
   ask, naming the decision and the conflict. Never pick a side silently.
3. **Decide what was left open, on the record.** The goal, the scope, a
   conflict with a decision, and what cannot be undone or costs money
   belong to the owner: ask once, with the options and the one you
   recommend, and keep working on the rest. What the owner left
   unspecified and the work needs, settle yourself, write it down as an
   assumed decision with its reason, and list it in your report.
4. **Specify before building**, as much as the work needs: acceptance
   criteria a test can check, and a look at what an owner tends to leave
   out (failures, limits, data, security, accessibility). A small fix
   needs only its test.
5. **Validate against a reference.** Behaviour defined by a specification,
   an existing product or an older version is checked against it, and the
   result is recorded. "It looks right" is not a check.
6. **Nothing is dropped silently.** Whatever is left undone, or moved to a
   later phase, is recorded in the project's backlog of deferred items with
   the reason, and the report says explicitly which item and to which
   phase it moved.
7. **A phase closes with its backlog at zero.** Deferred items are worked
   at the end of their phase, or moved to a named later phase with the
   owner told.
8. **Keep the records current at the end of each set of tasks:** the
   progress dashboard (status, what was just done, what comes next,
   backlog, forecast), the decision and project log (what, why, what
   followed, consequences) and the HISTORY file (one plain line per
   change).
9. **Tests.** Run the tests of what changed while working and the whole
   suite once before finishing. A bug is fixed with a test that fails
   first. Never skip, disable or loosen a test to make it pass. Report
   failures as they are.
10. **A lesson becomes a guard.** When the owner corrects you or a mistake
    repeats, record it and add what prevents it: a check before a rule, a
    sharper rule before a new one. The owner should not have to say it
    twice.
11. **Work lean.** Read only what the task touches, search instead of
    reading whole files, and do not paste long outputs. Tokens and the
    owner's attention are part of the cost.
12. **Report** with the outcome first, then what it depends on, then what
    you assumed, then what was left undone and where it went. Plain
    words, full sentences, absolute dates, no claim of a check that was
    not run.
13. **The skills apply by themselves.** The owner does not invoke them.
    In a repository just made from the project template (its
    `init-project.sh` is still there, or its AGENTS.md says the project
    has not been started), follow the `start-project` skill at once,
    with what the owner wrote as the brief.
<!-- agent-project-kit: working rules, end -->
