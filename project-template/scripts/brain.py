#!/usr/bin/env python3
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}
"""Finds, indexes and checks what the project knows: the Second Brain of docs/brain.

Usage: scripts/brain.py find WORDS...
       scripts/brain.py index
       scripts/brain.py check
       scripts/brain.py nudge

find    Prints what the project knows about the words: the notes of the
        brain that hold all of them, with their summary, then the lines of
        the records (decisions, lessons, backlog, inventory, project log,
        HISTORY.md, the other pages of docs) that hold all of them. Case
        and accents are ignored. Run it before a task, and whenever a
        question may have been answered before.
index   Rewrites the table of notes in docs/brain/README.md from the notes.
check   Fails when a note has no title, no summary or no valid Updated
        date, when its name is not lower case with hyphens, or when the
        table of notes is out of date. scripts/check-all.sh runs it.
nudge   The Claude Code Stop hook of .claude/settings.json. When the work
        changed files and no note of the brain, it asks the agent once,
        for that set of files, whether something learned should be
        written down (the update-brain skill). It never fails.

The method, and what goes in a note rather than in a record, are in
docs/brain/README.md.
"""
import datetime
import hashlib
import json
import pathlib
import re
import subprocess
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parent.parent
BRAIN = ROOT / 'docs' / 'brain'
INDEX = BRAIN / 'README.md'
BEGIN, END = '<!-- brain:index begin -->', '<!-- brain:index end -->'
NAME = re.compile(r'[a-z0-9]+(?:-[a-z0-9]+)*\.md')
MAX_RECORD_LINES = 20       # lines of the records printed by find before "and N more"
MAX_TEXT = 160              # characters of a line printed by find


def fold(text):
    """Text in lower case and without accents, so that "Decisão" finds "decisao"."""
    text = unicodedata.normalize('NFKD', text.casefold())
    return ''.join(c for c in text if not unicodedata.combining(c))


def rel(path):
    return path.relative_to(ROOT).as_posix()


def short(text):
    text = ' '.join(text.split())
    return text if len(text) <= MAX_TEXT else text[:MAX_TEXT - 1].rstrip() + '…'


def note_paths():
    """The notes of the brain: every page of docs/brain except its README."""
    if not BRAIN.is_dir():
        return []
    return sorted(p for p in BRAIN.glob('*.md') if p.name != 'README.md')


def parse(path):
    """The parts of a note: title, summary, tags, updated date and the whole text."""
    text = path.read_text(encoding='utf-8')
    title = re.search(r'^# (.+)$', text, re.M)
    summary = re.search(r'^> ?(.+(?:\n> ?.+)*)', text, re.M)
    tags = re.search(r'^Tags: *(.*)$', text, re.M)
    updated = re.search(r'^Updated: *(\S+) *$', text, re.M)
    return {
        'path': path,
        'title': title.group(1).strip() if title else '',
        'summary': ' '.join(re.sub(r'^> ?', '', summary.group(1), flags=re.M).split()) if summary else '',
        'tags': [t.strip() for t in tags.group(1).split(',') if t.strip()] if tags else [],
        'updated': updated.group(1) if updated else '',
        'text': text,
    }


def cell(text):
    """Text that can sit in a cell of a Markdown table."""
    return text.replace('|', '\\|').replace('\n', ' ')


def index_table(notes):
    """The table of notes that goes between the index marks of docs/brain/README.md."""
    lines = ['| Note | Summary | Tags | Updated |', '| --- | --- | --- | --- |']
    for n in sorted(notes, key=lambda n: fold(n['title'] or n['path'].name)):
        lines.append(f'| [{cell(n["title"] or n["path"].stem)}]({n["path"].name}) | {cell(n["summary"])} '
                     f'| {cell(", ".join(n["tags"]))} | {n["updated"]} |')
    return '\n'.join(lines)


def with_index(readme, notes):
    """The text of the README with its table of notes rewritten, or None without the marks."""
    pattern = re.compile(re.escape(BEGIN) + r'.*?' + re.escape(END), re.S)
    if not pattern.search(readme):
        return None
    return pattern.sub(lambda _: f'{BEGIN}\n{index_table(notes)}\n{END}', readme, count=1)


def problems_of(note):
    """What is wrong with one note."""
    where = rel(note['path'])
    found = []
    if not NAME.fullmatch(note['path'].name):
        found.append(f'{where}: name it in lower case with hyphens, for example payment-provider.md')
    if not note['title']:
        found.append(f'{where}: no title (a first line "# Subject")')
    if not note['summary']:
        found.append(f'{where}: no summary (a line that starts with ">", saying the current truth)')
    if note['updated'] != '{{' + 'TODAY}}':     # the template's own note, before init-project.sh
        try:
            datetime.date.fromisoformat(note['updated'])
        except ValueError:
            found.append(f'{where}: no valid date on its "Updated: YYYY-MM-DD" line')
    return found


def check():
    if not INDEX.exists():
        sys.exit('docs/brain/README.md is missing: take it from the template (docs/kit.md)')
    notes = [parse(p) for p in note_paths()]
    problems = [p for n in notes for p in problems_of(n)]
    readme = INDEX.read_text(encoding='utf-8')
    wanted = with_index(readme, notes)
    if wanted is None:
        problems.append(f'docs/brain/README.md: the marks {BEGIN} and {END} are missing')
    elif wanted != readme:
        problems.append('docs/brain/README.md: the table of notes is out of date; '
                        'run python3 scripts/brain.py index')
    if problems:
        print('\n'.join(problems), file=sys.stderr)
        sys.exit(1)
    print(f'The brain is in order: {len(notes)} note{"" if len(notes) == 1 else "s"}, all in its index')


def index():
    readme = INDEX.read_text(encoding='utf-8')
    notes = [parse(p) for p in note_paths()]
    wanted = with_index(readme, notes)
    if wanted is None:
        sys.exit(f'docs/brain/README.md has no {BEGIN} and {END} marks to write between')
    if wanted != readme:
        INDEX.write_text(wanted, encoding='utf-8')
    print(f'docs/brain/README.md lists {len(notes)} note{"" if len(notes) == 1 else "s"}')


def record_paths():
    """The records find searches after the notes: the registers first, then the other pages."""
    docs = ROOT / 'docs'
    first = [docs / 'decisions.md', docs / 'lessons.md', docs / 'backlog' / 'deferred.tsv']
    first += sorted((docs / 'inventory').glob('*.tsv')) if (docs / 'inventory').is_dir() else []
    first += [docs / 'project-log.md', ROOT / 'HISTORY.md']
    rest = sorted(p for p in docs.rglob('*') if p.suffix in ('.md', '.tsv') and p.is_file()
                  and BRAIN not in p.parents and p not in first)
    return [p for p in first + rest if p.exists()]


def find(words):
    terms = [fold(w) for w in words if w.strip()]
    if not terms:
        sys.exit('Say what to find: scripts/brain.py find WORDS...')
    hits = []
    for note in map(parse, note_paths()):
        text = fold(note['text'])
        if all(t in text for t in terms):
            head = fold(' '.join([note['title'], note['summary'], *note['tags']]))
            hits.append((-sum(head.count(t) for t in terms), -text.count(terms[0]), note))
    hits.sort(key=lambda h: h[:2])
    out = []
    if hits:
        out.append(f'Notes of the brain ({len(hits)}):')
        for *_, n in hits:
            out.append(f'  {rel(n["path"])}: {n["title"]}. {short(n["summary"])}')
    lines = []
    for path in record_paths():
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), start=1):
            if all(t in fold(line) for t in terms):
                lines.append(f'  {rel(path)}:{number}: {short(line)}')
    if lines:
        out.append(f'In the records ({len(lines)} lines):')
        out += lines[:MAX_RECORD_LINES]
        if len(lines) > MAX_RECORD_LINES:
            out.append(f'  and {len(lines) - MAX_RECORD_LINES} more: grep -rni with the same words in docs')
    if not out:
        out.append(f'Nothing is known about "{" ".join(words)}" yet. What you learn about it goes in a note '
                   '(the update-brain skill).')
    print('\n'.join(out))


def git(*args):
    try:
        done = subprocess.run(['git', '-C', str(ROOT), *args], capture_output=True, text=True, timeout=20)
        return done.stdout if done.returncode == 0 else ''
    except (OSError, subprocess.SubprocessError):
        return ''


def changed_paths():
    """The files this piece of work changed: in the working tree, and on the branch since main."""
    paths = {line[3:].split(' -> ')[-1].strip('"') for line in git('status', '--porcelain').splitlines()}
    for base in ('origin/main', 'main'):
        if git('rev-parse', '--verify', '--quiet', base).strip() and git('rev-parse', 'HEAD').strip():
            paths |= set(git('diff', '--name-only', f'{base}...HEAD').split())
            break
    return sorted(p for p in paths if p)


def nudge():
    try:
        event = json.loads(sys.stdin.read() or '{}')
    except ValueError:
        event = {}
    if event.get('stop_hook_active') or (ROOT / 'init-project.sh').exists() or not BRAIN.is_dir():
        return
    changed = changed_paths()
    if not changed or any(p.startswith('docs/brain/') for p in changed):
        return
    mark = git('rev-parse', '--git-path', 'brain-nudge').strip()
    if not mark:
        return
    mark = pathlib.Path(mark if pathlib.Path(mark).is_absolute() else ROOT / mark)
    key = hashlib.sha1('\n'.join(changed).encode()).hexdigest()
    if mark.exists() and mark.read_text(encoding='utf-8').strip() == key:
        return                                  # already asked about this set of files
    mark.write_text(key + '\n', encoding='utf-8')
    print(json.dumps({'decision': 'block', 'reason': (
        f'Second Brain: this work changed {len(changed)} files and no note of docs/brain. If it taught '
        'something the next session will need (how a part works, a fact of the domain or of an outside '
        'service, the cause of a problem, context the owner gave), write it now by the update-brain '
        'skill. If it taught nothing lasting, finish as you were. This reminder comes once for this '
        'set of files.')}))


def main(argv):
    command, args = (argv[0], argv[1:]) if argv else ('', [])
    if command == 'find':
        find(args)
    elif command == 'index' and not args:
        index()
    elif command == 'check' and not args:
        check()
    elif command == 'nudge' and not args:
        try:
            nudge()
        except Exception:                       # a hook must never stop the session
            pass
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main(sys.argv[1:])
