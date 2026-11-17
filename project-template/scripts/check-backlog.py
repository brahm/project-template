#!/usr/bin/env python3
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}
"""Checks docs/backlog/deferred.tsv, the register of what was left undone.

Usage: scripts/check-backlog.py [--phase NAME]

Without arguments it checks the form of the file, and the markers left
in the code: every TODO, FIXME, XXX or HACK in a file kept in git must
cite an open row, as in TODO(B-012). With --phase it also fails while a
row that moved to that phase (or to `end-of-phase`) is still open: run it
before closing a phase. The rules are in docs/backlog/README.md.
"""
import csv
import fnmatch
import pathlib
import re
import subprocess
import sys

COLUMNS = ['id', 'date', 'item', 'rows', 'task_set', 'reason', 'from_phase', 'to_phase', 'status',
           'closed_by']
STATUSES = {'open', 'done', 'dropped'}
ROOT = pathlib.Path(__file__).resolve().parent.parent
PATH = ROOT / 'docs' / 'backlog' / 'deferred.tsv'
# A marker, and the row it cites when it is written MARKER(B-nnn).
MARKER = re.compile(r'\b(TODO|FIXME|XXX|HACK)\b(?:\((B-\d{3,})\))?')
# Paths whose markers are not checked: prose, which names the markers
# without being one, and this script. Add the code of others kept in the
# repository (a vendored library, generated files) as glob patterns.
NOT_SCANNED = ['*.md', '*.mdc', 'scripts/check-backlog.py']


def check(rows, phase=None):
    """Returns the list of problems found in the rows of the register."""
    problems, seen = [], set()
    for n, row in enumerate(rows, start=1):
        where = f'row {n} ({row.get("id") or "no id"})'
        if not re.fullmatch(r'B-\d{3,}', row['id'] or ''):
            problems.append(f'{where}: id must be B- and at least three digits')
        if row['id'] in seen:
            problems.append(f'{where}: id used twice')
        seen.add(row['id'])
        if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', row['date'] or ''):
            problems.append(f'{where}: date must be YYYY-MM-DD')
        for col in ('item', 'task_set', 'reason', 'from_phase', 'to_phase'):
            if not (row[col] or '').strip(' -'):
                problems.append(f'{where}: {col} is empty')
        if row['status'] not in STATUSES:
            problems.append(f'{where}: status must be one of {sorted(STATUSES)}')
        elif row['status'] != 'open' and not (row['closed_by'] or '').strip(' -'):
            problems.append(f'{where}: a {row["status"]} row needs closed_by')
        if phase and row['status'] == 'open' and row['to_phase'] in (phase, 'end-of-phase'):
            problems.append(f'{where}: still open, and phase "{phase}" cannot close: {row["item"]}')
    return problems


def tracked_files():
    """Returns the paths, relative to the root, of the files kept in git;
    every file under the root when it is not a git repository."""
    try:
        out = subprocess.run(['git', 'ls-files', '-z'], cwd=ROOT, capture_output=True, check=True)
        names = [n for n in out.stdout.decode('utf-8').split('\0') if n]
    except (OSError, subprocess.CalledProcessError):
        names = [str(p.relative_to(ROOT)) for p in ROOT.rglob('*')
                 if p.is_file() and '.git' not in p.parts]
    return [n for n in names
            if not any(fnmatch.fnmatch(n, pat) or fnmatch.fnmatch(pathlib.Path(n).name, pat)
                       for pat in NOT_SCANNED)]


def check_markers(rows, files):
    """Returns the problems of the markers in the given files: a marker
    must cite a row of the register that is still open."""
    status = {row['id']: row['status'] for row in rows}
    problems = []
    for name in files:
        try:
            text = (ROOT / name).read_text(encoding='utf-8')
        except (OSError, UnicodeDecodeError):
            continue
        for n, line in enumerate(text.splitlines(), start=1):
            for m in MARKER.finditer(line):
                where, marker, row = f'{name}:{n}', m.group(1), m.group(2)
                if not row:
                    problems.append(f'{where}: {marker} cites no backlog row; write {marker}(B-nnn) '
                                    f'with a row of docs/backlog/deferred.tsv, or remove it')
                elif row not in status:
                    problems.append(f'{where}: {marker}({row}) cites a row that is not in the register')
                elif status[row] != 'open':
                    problems.append(f'{where}: {marker}({row}) cites a row that is {status[row]}; '
                                    f'remove the note')
    return problems


def main(argv):
    phase = None
    if argv[:1] == ['--phase'] and len(argv) == 2:
        phase = argv[1]
    elif argv:
        sys.exit(__doc__)
    with open(PATH, newline='', encoding='utf-8') as f:
        lines = [line for line in f if not line.startswith('#')]
    reader = csv.DictReader(lines, delimiter='\t', quoting=csv.QUOTE_NONE)
    if reader.fieldnames != COLUMNS:
        sys.exit(f'{PATH}: the columns must be {COLUMNS}')
    rows = list(reader)
    problems = check(rows, phase) + check_markers(rows, tracked_files())
    for p in problems:
        print(p, file=sys.stderr)
    if problems:
        sys.exit(1)
    print(f'{len(rows)} rows, {sum(r["status"] == "open" for r in rows)} open')


if __name__ == '__main__':
    main(sys.argv[1:])
