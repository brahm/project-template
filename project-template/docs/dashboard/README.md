# Progress dashboard

One page that says where {{PROJECT_NAME}} stands: items done per track and
per phase, what was just done, what comes next, the backlog and the
forecast. `scripts/dashboard.py` generates it from files of this
repository, so nothing on it is typed by hand. The page is in
{{OWNER_LANGUAGE}}, the language of the project owner (`language` in
[config.toml](config.toml)).

## Where it is published

| Where | How it is updated |
| --- | --- |
| A file in the repository's site (optional) | `.github/workflows/dashboard.yml` regenerates it from `main` and publishes it with GitHub Pages |
| A hosted page of the owner (optional, for example a claude.ai Artifact) | By the agent that ends a set of tasks, with step 3 below, always at the same address: {{DASHBOARD_URL}} |

## Update it when a set of tasks ends

A set of tasks is a pull request, a phase or a thread of work. Before its
last commit:

1. Bring the sources up to date (next section).
2. Run `python3 scripts/dashboard.py --record --artifact /tmp/dashboard.html`.
   `--record` writes today's row in [`history.tsv`](history.tsv), the
   changes of status in `changes.tsv` and the new `snapshot.tsv`; commit
   the three with the rest of the change.
3. If the owner has a hosted page, publish `/tmp/dashboard.html` to it **at
   the same address**. With a claude.ai Artifact: read the address first,
   then publish the file with `url` set to it. Never publish without the
   address, which would create a second page.

The same moment is when the set of tasks gets its entry in the
[project log](../project-log.md) and its lines in
[HISTORY.md](../../HISTORY.md). The dashboard does not read them, but the
three are kept up to date together.

## The sources, and who changes them

| File | What the page reads | When to change it |
| --- | --- | --- |
| [`config.toml`](config.toml) | Title, target, repository, time zone, language, tracks | When the project starts, or adds a track |
| [`../inventory/*.tsv`](../inventory/README.md) | Scope, status, phase and note of every item | When an item changes status |
| [`../roadmap.md`](../roadmap.md) | The table of phases: id, name, what it delivers, rows, estimate in days | When the plan changes |
| [`phases.tsv`](phases.tsv) | The status of each phase (`not-started`, `in-progress`, `done`), the days it started and ended, and its track (`-` for none) | When a phase starts or ends |
| [`forecast.tsv`](forecast.tsv) | The estimate of the plan: its day and the least, likely and most days | When the roadmap corrects its estimate |
| [`../backlog/deferred.tsv`](../backlog/README.md) | What was left undone, and the phase it moved to | By the rules of the backlog |
| [`history.tsv`](history.tsv), [`snapshot.tsv`](snapshot.tsv), [`changes.tsv`](changes.tsv) | One row per recorded day; the status of everything at the last record; what changed between records | Only through `--record` |

The pull requests come from GitHub (`gh api search/issues`) when `repo` is
set and `gh` answers; otherwise the page lists the merges of the local git
history.

## What was just done, and what comes next

"What was just done" lists what changed status in the last three recorded
days: the script compares the files with `snapshot.tsv`, and `--record`
writes the differences in `changes.tsv` with the day. So a set of tasks
shows on the page only if it updated the inventory, `phases.tsv` and the
backlog before `--record` ran. The section also lists the latest pull
requests.

"What comes next" lists the phases in progress and the next one of each
track, in the order of the roadmap. A track only offers its next phase when
every phase without a track before it is done, so a common base comes
first. Each phase shows its items still to do and the backlog items that
come back in it.

## How an item counts as done

`scope` is `In`, `status` is `Done` and `review` is `-`. `Done` with a
reason in `review` shows as "Done, to review" and does not count.

## How the forecast is worked out

The work is measured in the estimated days of the phases. A phase that is
`done` counts whole; a phase `in-progress` counts by the share of its
inventory rows that are done; the others count nothing. The forecast is
the day the page is generated plus the share still to do of the least,
likely and most days of `forecast.tsv`. With no progress it moves one day
later each day. It is an estimate, not a commitment.

The script stops with a message when the sources disagree: a phase of the
roadmap without a row in `phases.tsv`, a phase in the inventory that the
roadmap does not have, an id used twice, or an unknown status. It warns
when the row count of a phase in the roadmap differs from the inventory.
`--check` runs those checks alone; `scripts/check-all.sh` runs it.

## Changing the page

The words are in `LABELS` at the top of the script (English and Brazilian
Portuguese); add a language by copying a block. The colours are CSS
variables in `CSS`, with a dark variant.
