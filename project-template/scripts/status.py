#!/usr/bin/env python3
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}
"""Says where the project stands, in a few lines, for an agent starting a session.

Usage: scripts/status.py

An agent that starts work needs to know the phase in progress, what comes
next, what was left undone and what waits for the owner. Reading the pages
that hold those facts costs thousands of tokens each session; this script
reads them and prints the answer in about twenty lines. Claude Code runs it
when a session starts (.claude/settings.json); other agents run it first,
as rule 1 of AGENTS.md says.

It also tells a project that was just made from the template from one that
is under way: while init-project.sh is at the root, or AGENTS.md still has
its "not started" section, the only thing it prints is the instruction to
start the project.

The numbers come from the same functions as the dashboard
(scripts/dashboard.py), so the two cannot disagree. The script never fails:
a problem in the sources is printed as the first thing to fix.
"""
import collections
import datetime
import pathlib
import re
import subprocess
import sys
import tomllib
import zoneinfo

ROOT = pathlib.Path(__file__).resolve().parent.parent
NOT_STARTED_MARK = '<!-- kit:not-started begin -->'
START_SKILL = '.claude/skills/start-project/SKILL.md'
MAX_ITEMS = 8          # rows listed per phase before "and N more"
MAX_TEXT = 90          # characters of an item's sentence that are shown


def not_started():
    """The instruction to print when the project has not been started, or None."""
    agents = ROOT / 'AGENTS.md'
    marked = agents.exists() and NOT_STARTED_MARK in agents.read_text(encoding='utf-8')
    if (ROOT / 'init-project.sh').exists():
        what = 'init-project.sh is still at the root, so the placeholders are not filled'
    elif marked:
        what = 'the placeholders are filled, but the project has no goals, inventory or roadmap yet'
    else:
        return None
    return (f'STATE: NOT STARTED. This repository was just made from the template: {what}.\n'
            f'Do this now, before any other work and without waiting to be asked: follow {START_SKILL},\n'
            "taking the owner's message as the brief. It ends by deleting the \"not started\" section of AGENTS.md.")


def short(text):
    """A sentence cut to MAX_TEXT characters."""
    text = ' '.join(text.split())
    return text if len(text) <= MAX_TEXT else text[:MAX_TEXT - 1].rstrip() + '…'


def git(*args):
    """The output of a git command at the root, or '' when git cannot answer."""
    try:
        return subprocess.run(['git', '-C', str(ROOT), *args], capture_output=True, text=True,
                              timeout=20).stdout
    except (OSError, subprocess.SubprocessError):
        return ''


def open_lessons():
    """The ids of the rows of docs/lessons.md that have no guard yet."""
    path = ROOT / 'docs' / 'lessons.md'
    if not path.exists():
        return []
    rows = re.findall(r'^\| (L-\d{3,}) \|.*\| *open *\|$', path.read_text(encoding='utf-8'), re.M)
    return rows


def phase_lines(dk, phase, items, backlog, label):
    """The lines for one phase: its progress, its rows still to do, its backlog."""
    todo = [i for i in items if i['phase'] == phase['id'] and i['state'] in dk.STATES
            and i['state'] != 'done']
    lines = [f'{label}: {phase["id"]} {phase["name"]}, {phase["counts"]["done"]} of {phase["total"]} '
             'items done.']
    for i in todo[:MAX_ITEMS]:
        state = 'Done, to review: ' + i['review'].strip() if i['state'] == 'review' else i['status'].strip()
        lines.append(f'  {i["id"]} ({state}) {short(i["item"])}')
    if len(todo) > MAX_ITEMS:
        lines.append(f'  and {len(todo) - MAX_ITEMS} more: grep -P "\\t{phase["id"]}\\t" docs/inventory/*.tsv')
    back = [b for b in backlog if b['status'] == 'open' and b['to_phase'] in (phase['id'], 'end-of-phase')]
    for b in back[:MAX_ITEMS]:
        lines.append(f'  {b["id"]} (backlog, comes back in this phase) {short(b["item"])}')
    if len(back) > MAX_ITEMS:
        lines.append(f'  and {len(back) - MAX_ITEMS} more backlog rows: docs/backlog/deferred.tsv')
    return lines


def digest():
    """The lines of the state of a project under way."""
    import dashboard as dk          # the same loaders as the dashboard

    cfg = tomllib.loads((dk.HERE / 'config.toml').read_text(encoding='utf-8'))
    cfg.setdefault('tracks', {'main': 'Main'})
    try:
        tz = zoneinfo.ZoneInfo(cfg.get('timezone') or 'UTC')
    except (zoneinfo.ZoneInfoNotFoundError, ValueError):
        tz = datetime.timezone.utc
    today = datetime.datetime.now(tz).date()

    items = dk.load_items(cfg['tracks'])
    phases = dk.load_phases(items)
    backlog = dk.read_tsv(ROOT / 'docs' / 'backlog' / 'deferred.tsv')
    fc = dk.forecast(phases, today)
    totals = collections.Counter(i['state'] for i in items)
    scope = sum(totals[k] for k in dk.STATES)
    open_rows = [b for b in backlog if b['status'] == 'open']

    out = [f'{cfg.get("title", "Project")}, {today.isoformat()}: {totals["done"]} of {scope} items done'
           + (f', {totals["review"]} done but to review' if totals['review'] else '')
           + f'; {len(open_rows)} backlog rows open; forecast {fc["now"]["likely"].isoformat()}.']

    current = [p for p in phases if p['status'] == 'in-progress']
    listed = 0
    for p in current:
        lines = phase_lines(dk, p, items, backlog, 'Phase in progress')
        listed += len(lines) - 1
        out += lines
    upcoming = dk.next_phases(phases)
    if not current:
        out.append('No phase is in progress.')
    if listed == 0 and upcoming:
        # Nothing is left in the phases in progress: show the rows of what comes next.
        out += phase_lines(dk, upcoming[0], items, backlog, 'Next phase')
        upcoming = upcoming[1:]
    if upcoming and current:
        out.append('Next: ' + ', '.join(f'{p["id"]} {p["name"]}' for p in upcoming) + '.')
    if not current and not dk.next_phases(phases):
        out.append('Every phase is done.')

    assumed = dk.assumed_decisions()
    if assumed:
        out.append('Decisions assumed and not yet confirmed by the owner: '
                   + ', '.join(d['id'] for d in assumed) + ' (docs/decisions.md).')
    lessons = open_lessons()
    if lessons:
        out.append('Lessons without a guard yet: ' + ', '.join(lessons) + ' (docs/lessons.md).')

    _, pending = dk.load_changes(dk.snapshot_now(items, phases, backlog), today)
    if pending:
        out.append(f'{len(pending)} changes of status are not recorded yet: run '
                   '`python3 scripts/dashboard.py --record` when the set of tasks closes.')

    branch = git('rev-parse', '--abbrev-ref', 'HEAD').strip()
    if branch:
        dirty = len(git('status', '--porcelain').splitlines())
        last = git('log', '-1', '--format=%cs %s').strip()
        out.append(f'Git: branch {branch}' + (f', {dirty} files changed and not committed' if dirty else '')
                   + (f'; last commit {short(last)}' if last else '') + '.')
    notes = [p for p in (ROOT / 'docs' / 'brain').glob('*.md') if p.name != 'README.md']
    out.append(f'Second Brain: {len(notes)} notes in docs/brain. Before a task: '
               '`python3 scripts/brain.py find WORDS`.')
    out.append('Rules: AGENTS.md. Its skills apply by moment (rule 2); the owner does not name them.')
    return out


def main():
    start = not_started()
    if start:
        print(start)
        return
    try:
        print('\n'.join(digest()))
    except SystemExit as stop:      # the loaders of the dashboard stop with a message
        print(f'STATE: THE SOURCES DISAGREE. Fix this before other work: {stop.code}')
    except Exception as error:      # never break the start of a session
        print(f'scripts/status.py could not read the project ({type(error).__name__}: {error}). '
              'Run `python3 scripts/dashboard.py --check` to see why.')


if __name__ == '__main__':
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    main()
