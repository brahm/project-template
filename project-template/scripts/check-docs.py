#!/usr/bin/env python3
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}
"""Checks that the pages of the project still agree with each other.

Usage: scripts/check-docs.py

Documentation goes wrong quietly: a page is renamed and a link to it
breaks, a decision is cited that was never written down, a placeholder of
the template is left in a page. Nobody notices until an agent or a visitor
follows the link. This script fails on:

  1. a link from one Markdown page to a file of the repository that does
     not exist;
  2. a decision (D-nnn), a backlog row (B-nnn), a lesson (L-nnn) or an
     inventory row cited in the records that its register does not have;
  3. a decision log that is not well formed: an id used twice, a status
     that is not one of the three, a "Replaced by" that names no decision;
  4. a placeholder of the template (a name in capitals between two pairs
     of braces) left after the project was initialised.

The records checked for ids are the pages an agent writes as it works:
goals, roadmap, architecture, verification, the project log, the
specifications, the lessons, HISTORY.md and the TSV registers. Pages that
only show the form of an id as an example (the writing style, the skills)
are not checked for ids.
"""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKIP_DIRS = {'.git', 'node_modules', 'target', 'dist', 'build', '_site', 'vendor', '.venv', 'venv',
             '__pycache__', 'LICENSES'}
ID_RECORDS = ['HISTORY.md', 'docs/goals.md', 'docs/roadmap.md', 'docs/architecture.md',
              'docs/verification.md', 'docs/project-log.md', 'docs/lessons.md', 'docs/decisions.md']
DECISION_STATUS = re.compile(r'Current|Current \(assumed, not contested\)|Replaced by (D-\d{3,})')
LINK = re.compile(r'\[[^\]\n]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
PLACEHOLDER = re.compile(r'(?<!\$)\{\{[A-Z_]+\}\}')


def files(suffixes):
    """Every file of the repository with one of the suffixes.

    Git lists them when it can (tracked files and new ones, without what
    .gitignore names); otherwise the tree is walked, outside SKIP_DIRS.
    Symbolic links are left out, so the skills linked for other agents are
    read once.
    """
    try:
        out = subprocess.run(['git', '-C', str(ROOT), 'ls-files', '-co', '--exclude-standard', '-z'],
                             capture_output=True, text=True, timeout=60, check=True).stdout
        listed = [ROOT / name for name in out.split('\0') if name]
        return sorted(p for p in listed if p.suffix in suffixes and p.is_file() and not p.is_symlink()
                      and not SKIP_DIRS & set(p.relative_to(ROOT).parts))
    except (OSError, subprocess.SubprocessError):
        pass
    found = []
    stack = [ROOT]
    while stack:
        for path in sorted(stack.pop().iterdir()):
            if path.is_symlink():
                continue
            if path.is_dir():
                if path.name not in SKIP_DIRS:
                    stack.append(path)
            elif path.suffix in suffixes:
                found.append(path)
    return sorted(found)


def without_code(text):
    """The text of a Markdown page with its code blocks and code spans blanked.

    Links and ids inside code are examples, not references, so they are
    not checked. The line count is kept so that messages name the line.
    """
    text = re.sub(r'^(```|~~~).*?^\1[^\n]*$', lambda m: '\n' * m.group(0).count('\n'), text,
                  flags=re.S | re.M)
    return re.sub(r'`[^`\n]*`', '', text)


def rel(path):
    return path.relative_to(ROOT).as_posix()


def read(path):
    """The text of a file, or None when it is not UTF-8 (a binary file, or another encoding)."""
    try:
        return path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        return None


def check_links(problems):
    """A link to a file of the repository must lead to a file that exists."""
    for page in files({'.md'}):
        text = read(page)
        if text is None:
            problems.append(f'{rel(page)}: not UTF-8, so its links cannot be checked')
            continue
        text = without_code(text)
        for n, line in enumerate(text.splitlines(), start=1):
            for target in LINK.findall(line):
                if re.match(r'[a-z][a-z0-9+.-]*:|#|<', target, re.I):
                    continue                    # a web address, a mail address or an anchor
                file = target.split('#')[0].split('?')[0]
                base = ROOT if file.startswith('/') else page.parent
                if not (base / file.lstrip('/')).exists():
                    problems.append(f'{rel(page)}:{n}: the link to {target} leads nowhere')


def table_ids(path, prefix):
    """The ids of the given prefix that start a row of the tables of a Markdown page."""
    if not path.exists():
        return []
    return re.findall(rf'^\| ({prefix}-\d{{3,}}) \|', path.read_text(encoding='utf-8'), re.M)


def tsv_ids(path):
    """The first column of the rows of a TSV register."""
    ids = []
    for line in path.read_text(encoding='utf-8').splitlines():
        if line and not line.startswith('#') and not line.startswith('id\t'):
            ids.append(line.split('\t')[0])
    return ids


def check_decisions(problems):
    """The decision log: ids used once, a known status, replacements that exist."""
    path = ROOT / 'docs' / 'decisions.md'
    if not path.exists():
        return
    rows = re.findall(r'^\| (D-\d{3,}) \| .+ \| (.+?) \|$', path.read_text(encoding='utf-8'), re.M)
    ids = [r[0] for r in rows]
    for i in sorted({i for i in ids if ids.count(i) > 1}):
        problems.append(f'docs/decisions.md: {i} is used twice')
    for i, status in rows:
        m = DECISION_STATUS.fullmatch(status.strip())
        if not m:
            problems.append(f'docs/decisions.md: {i} has the status "{status.strip()}"; it must be Current, '
                            'Current (assumed, not contested) or Replaced by D-nnn')
        elif m.group(1) and m.group(1) not in ids:
            problems.append(f'docs/decisions.md: {i} is replaced by {m.group(1)}, which does not exist')


def check_ids(problems):
    """An id cited in the records must exist in its register."""
    inventory = [i for p in sorted((ROOT / 'docs' / 'inventory').glob('*.tsv')) for i in tsv_ids(p)]
    backlog_path = ROOT / 'docs' / 'backlog' / 'deferred.tsv'
    known = {
        'D': set(table_ids(ROOT / 'docs' / 'decisions.md', 'D')),
        'B': set(tsv_ids(backlog_path)) if backlog_path.exists() else set(),
        'L': set(table_ids(ROOT / 'docs' / 'lessons.md', 'L')),
    }
    registers = {'D': 'docs/decisions.md', 'B': 'docs/backlog/deferred.tsv', 'L': 'docs/lessons.md'}
    for i in sorted({i for i in inventory if inventory.count(i) > 1}):
        problems.append(f'docs/inventory: {i} is used twice')
    # The prefixes of the inventory are the project's own (F-, W-, ...).
    for prefix in {i.split('-')[0] for i in inventory if '-' in i} - set(known):
        known[prefix] = {i for i in inventory if i.startswith(prefix + '-')}
        registers[prefix] = 'docs/inventory'
    cited = re.compile(r'\b(' + '|'.join(sorted(known)) + r')-(\d{3,})\b')

    pages = [ROOT / p for p in ID_RECORDS] + sorted((ROOT / 'docs' / 'inventory').glob('*.tsv'))
    if backlog_path.exists():
        pages.append(backlog_path)
    specs = ROOT / 'docs' / 'specs'
    if specs.is_dir():
        pages += [p for p in sorted(specs.glob('*.md')) if p.name != 'README.md']
    for page in pages:
        if not page.exists():
            continue
        text = page.read_text(encoding='utf-8')
        if page.suffix == '.md':
            text = without_code(text)
        for n, line in enumerate(text.splitlines(), start=1):
            for prefix, number in cited.findall(line):
                if f'{prefix}-{number}' not in known[prefix]:
                    problems.append(f'{rel(page)}:{n}: {prefix}-{number} is cited, but '
                                    f'{registers[prefix]} has no such row')


def check_placeholders(problems):
    """Once init-project.sh is gone, no placeholder of the template may be left."""
    if (ROOT / 'init-project.sh').exists():
        return
    for page in files({'.md', '.tsv', '.toml', '.py', '.sh', '.yml', '.yaml', '.json'}):
        text = read(page)
        if text is None:
            continue                            # not text: no placeholder to fill
        for n, line in enumerate(text.splitlines(), start=1):
            if PLACEHOLDER.search(line):
                problems.append(f'{rel(page)}:{n}: a placeholder of the template is left: '
                                f'{PLACEHOLDER.search(line).group(0)}')


def main(argv):
    if argv:
        sys.exit(__doc__)
    problems = []
    check_links(problems)
    check_decisions(problems)
    check_ids(problems)
    check_placeholders(problems)
    for p in problems:
        print(p, file=sys.stderr)
    if problems:
        sys.exit(1)
    print('The pages agree: links, ids and the decision log')


if __name__ == '__main__':
    main(sys.argv[1:])
