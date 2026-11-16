#!/usr/bin/env python3
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}
"""Checks that a set of tasks updated the records of the project.

Usage: scripts/check-records.py [--base REF]

AGENTS.md asks for four records at the end of each set of tasks: the
inventory and phases, the dashboard, the project log and HISTORY.md. They
are the first thing forgotten when a session is long, so this script
fails while one of them is behind:

  1. the dashboard was not recorded: an item, a phase or a backlog row
     changed status since the last `scripts/dashboard.py --record`;
  2. the change has no line in HISTORY.md;
  3. the change has no entry in docs/project-log.md.

Checks 2 and 3 compare the working tree with the branch the work started
from: --base names it (the CI passes the base branch of the pull
request); without it, the default branch of `origin` is used. On the
default branch itself, or without git, they are skipped and the script
says so. A change that touches nothing but the records passes.

Run it through scripts/check-all.sh once the records are written
(the `close-task-set` skill does it in that order).
"""
import argparse
import datetime
import pathlib
import subprocess
import sys
import tomllib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import dashboard as dk          # the same loaders as the dashboard  # noqa: E402

ROOT = dk.ROOT
HISTORY = 'HISTORY.md'
LOG = 'docs/project-log.md'
# A change limited to these files is the records being brought up to date.
RECORDS = {HISTORY, LOG, 'docs/dashboard/history.tsv', 'docs/dashboard/changes.tsv',
           'docs/dashboard/snapshot.tsv'}


def git(*args):
    """The output of a git command at the root, or None when it fails."""
    try:
        done = subprocess.run(['git', '-C', str(ROOT), *args], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.SubprocessError):
        return None
    return done.stdout if done.returncode == 0 else None


def not_recorded():
    """The changes of status since the last record of the dashboard."""
    cfg = tomllib.loads((dk.HERE / 'config.toml').read_text(encoding='utf-8'))
    items = dk.load_items(cfg.get('tracks', {'main': 'Main'}))
    phases = dk.load_phases(items)
    backlog = dk.read_tsv(ROOT / 'docs' / 'backlog' / 'deferred.tsv')
    _, pending = dk.load_changes(dk.snapshot_now(items, phases, backlog), datetime.date.today())
    return pending


def base_commit(ref):
    """The commit the work started from, and a note when there is none to compare with."""
    if git('rev-parse', '--git-dir') is None:
        return None, 'this is not a git repository'
    candidates = [ref] if ref else []
    head = git('symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
    if head:
        candidates.append(head.strip())
    candidates += ['origin/main', 'origin/master']
    for name in candidates:
        if git('rev-parse', '--verify', '--quiet', name + '^{commit}') is None:
            continue
        base = git('merge-base', name, 'HEAD')
        if base is None:
            return None, f'{name} and this branch share no history here (a shallow clone?)'
        base = base.strip()
        if base == (git('rev-parse', 'HEAD') or '').strip() and not changed_since('HEAD'):
            return None, f'nothing changed since {name}'
        return base, None
    return None, 'there is no base branch to compare with' + (f' ({ref} was not found)' if ref else '')


def changed_since(commit):
    """The files that differ from a commit: committed, not committed, and new."""
    names = set((git('diff', '--name-only', commit) or '').split('\n'))
    names |= set((git('ls-files', '--others', '--exclude-standard') or '').split('\n'))
    return {n for n in names if n}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--base')
    args = ap.parse_args()
    problems = []

    pending = not_recorded()
    if pending:
        ids = ', '.join(c['id'] for c in pending[:8]) + (' ...' if len(pending) > 8 else '')
        problems.append(f'{len(pending)} changes of status are not recorded ({ids}): run '
                        '`python3 scripts/dashboard.py --record` and commit docs/dashboard/')

    base, note = base_commit(args.base)
    if base is None:
        print(f'(HISTORY.md and the project log were not compared: {note})')
    else:
        changed = changed_since(base)
        if changed - RECORDS:
            if HISTORY not in changed:
                problems.append(f'{HISTORY} has no line for this set of tasks (rule "History" of AGENTS.md)')
            if LOG not in changed and (ROOT / LOG).exists():
                problems.append(f'{LOG} has no entry for this set of tasks (rule "Project log" of AGENTS.md)')

    for p in problems:
        print(p, file=sys.stderr)
    if problems:
        sys.exit(1)
    print('The records are current')


if __name__ == '__main__':
    main()
