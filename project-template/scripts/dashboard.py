#!/usr/bin/env python3
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}
"""Builds the progress dashboard of the project from files of the repository.

Usage: scripts/dashboard.py [--out FILE] [--artifact FILE] [--record]
                            [--check] [--date YYYY-MM-DD] [--no-prs]

  --out FILE       write the page as a whole HTML document (a website)
  --artifact FILE  write it as a fragment without <html>, <head> and
                   <body>, the form a hosted page such as a claude.ai
                   Artifact is published in
  --record         add or replace today's row of docs/dashboard/history.tsv,
                   log what changed status since the last record in
                   changes.tsv, and renew snapshot.tsv
  --check          only check that the sources agree, and write nothing
  --date           the day the page is generated for (default: today in
                   the time zone of config.toml); for tests
  --no-prs         do not ask GitHub for the pull requests; read the
                   merges of the local git history instead

Every number on the page is read from a file of the repository:

  docs/dashboard/config.toml    title, repository, language, tracks
  docs/inventory/<track>.tsv    the items, their scope, status and phase
  docs/roadmap.md               the phases and their estimates in days
  docs/dashboard/phases.tsv     which phases started and ended
  docs/dashboard/forecast.tsv   the estimate of the plan, in days
  docs/dashboard/history.tsv    one row per day the dashboard was recorded
  docs/dashboard/snapshot.tsv   the status of everything at the last record
  docs/dashboard/changes.tsv    what changed status between two records
  docs/backlog/deferred.tsv     what was left undone
  docs/decisions.md             the decisions assumed by an agent that the
                                owner has not confirmed yet

The recent pull requests come from GitHub (`gh api search/issues`), or
from the merges of the git history when `gh` cannot answer. How the numbers
are worked out is in docs/dashboard/README.md. Needs Python 3.11 or later.
"""
import argparse
import collections
import csv
import datetime
import html
import json
import pathlib
import re
import subprocess
import sys
import tomllib
import zoneinfo

ROOT = pathlib.Path(__file__).resolve().parent.parent
HERE = ROOT / 'docs' / 'dashboard'

# The states of an item in scope, in the order the bars stack them. `done`
# is the only one that counts as finished.
STATES = ['done', 'review', 'partial', 'started', 'missing']
STATUS_TO_STATE = {'Partial': 'partial', 'Started': 'started', 'Missing': 'missing'}
PHASE_STATUSES = ['not-started', 'in-progress', 'done']
HISTORY_COLUMNS = ['date', 'in_scope', *STATES, 'backlog_open', 'forecast']

# The words of the page, per language. Add a language by copying a block.
LABELS = {
    'en': {
        'done': 'Done', 'review': 'Done, to review', 'partial': 'Partial', 'started': 'Started',
        'missing': 'Missing', 'out': 'Out of scope', 'na': 'Not applicable',
        'not-started': 'Not started', 'in-progress': 'In progress', 'phase-done': 'Done',
        'lead': '<b>{done} of {scope} items</b> of {target} are done, {pct}% of the scope.',
        'current': 'Phase in progress: {phases}.', 'no-current': 'No phase in progress.',
        'fc-lead': 'The forecast is <b>{date}</b>, {slip}.',
        'fc-same': 'the same as the plan', 'fc-later': '{n} days later than the plan',
        'fc-earlier': '{n} days earlier than the plan',
        'stamp': 'Generated on {date} from commit <code>{commit}</code>.',
        'k-done': 'Items done', 'k-backlog': 'Backlog open', 'k-forecast': 'Forecast',
        'k-phase': 'Phases done', 'k-since': '{n:+d} since {date}',
        'tracks': 'By track', 'phases': 'Phases', 'phase': 'Phase', 'delivers': 'What it delivers',
        'status': 'Status', 'days': 'Days', 'progress': 'Progress', 'dates': 'Dates',
        'just-done': 'What was just done', 'changes': 'Changes of status since the last records',
        'no-changes': 'No change of status recorded yet.', 'prs': 'Recent pull requests',
        'prs-from': 'from {source}', 'no-prs': 'No pull request found.',
        'next': 'What comes next', 'to-do': 'Items still to do', 'backlog-back': 'Backlog items that come back here',
        'nothing-next': 'Every phase is done.',
        'backlog': 'Backlog: what was left undone', 'backlog-open': 'Open items',
        'no-backlog': 'Nothing open.', 'item': 'Item', 'reason': 'Reason', 'from-to': 'From, to',
        'assumed': 'Decisions waiting for the owner', 'decision': 'Decision', 'date': 'Date',
        'assumed-note': 'Settled by an agent because nothing said otherwise. Each one stands until the owner confirms it or replaces it.',
        'forecast': 'Forecast', 'fc-plan': 'Plan of {date}: {low} to {high}, likely {likely}.',
        'fc-now': 'Today: {low} to {high}, likely {likely}. {left}% of the estimated work is left.',
        'fc-note': 'A forecast, not a commitment: phases done count whole, phases in progress count by their share of items done.',
        'history': 'History', 'history-note': 'Items done on each recorded day.',
        'items': 'Every item', 'all': 'All', 'search': 'Search', 'of': 'of', 'track': 'Track',
        'area': 'Area', 'id': 'Id', 'no-js': 'The list needs JavaScript. The same data is in docs/inventory.',
        'sources': 'Sources: <code>docs/inventory</code>, <code>docs/roadmap.md</code>, <code>docs/backlog</code> and <code>docs/dashboard</code>. Generated by <code>scripts/dashboard.py</code>.',
        'b-open': 'open', 'b-done': 'done', 'b-dropped': 'dropped',
        'new': 'new', 'kind-item': 'item', 'kind-phase': 'phase', 'kind-backlog': 'backlog',
        'months': ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
                   'September', 'October', 'November', 'December'],
        'long-date': '{d} {month} {y}', 'decimal': '.', 'html-lang': 'en',
    },
    'pt-BR': {
        'done': 'Pronto', 'review': 'Pronto, a rever', 'partial': 'Parcial', 'started': 'Iniciado',
        'missing': 'Falta', 'out': 'Fora do escopo', 'na': 'Não se aplica',
        'not-started': 'Não iniciada', 'in-progress': 'Em andamento', 'phase-done': 'Concluída',
        'lead': '<b>{done} dos {scope} itens</b> de {target} estão prontos, {pct}% do escopo.',
        'current': 'Fase em andamento: {phases}.', 'no-current': 'Nenhuma fase em andamento.',
        'fc-lead': 'A previsão é <b>{date}</b>, {slip}.',
        'fc-same': 'igual à do plano', 'fc-later': '{n} dias depois do plano',
        'fc-earlier': '{n} dias antes do plano',
        'stamp': 'Gerado em {date} a partir do commit <code>{commit}</code>.',
        'k-done': 'Itens prontos', 'k-backlog': 'Pendências abertas', 'k-forecast': 'Previsão',
        'k-phase': 'Fases concluídas', 'k-since': '{n:+d} desde {date}',
        'tracks': 'Por frente', 'phases': 'Fases', 'phase': 'Fase', 'delivers': 'O que entrega',
        'status': 'Situação', 'days': 'Dias', 'progress': 'Andamento', 'dates': 'Datas',
        'just-done': 'Acabou de ser feito', 'changes': 'Mudanças de situação nos últimos registros',
        'no-changes': 'Nenhuma mudança de situação registrada ainda.', 'prs': 'Pull requests recentes',
        'prs-from': 'do {source}', 'no-prs': 'Nenhum pull request encontrado.',
        'next': 'A seguir', 'to-do': 'Itens a fazer', 'backlog-back': 'Pendências que voltam nesta fase',
        'nothing-next': 'Todas as fases estão concluídas.',
        'backlog': 'Pendências: o que ficou sem fazer', 'backlog-open': 'Itens abertos',
        'no-backlog': 'Nada aberto.', 'item': 'Item', 'reason': 'Motivo', 'from-to': 'De, para',
        'assumed': 'Decisões aguardando o dono', 'decision': 'Decisão', 'date': 'Data',
        'assumed-note': 'Tomadas por um agente porque nada dizia o contrário. Cada uma vale até o dono confirmar ou substituir.',
        'forecast': 'Previsão', 'fc-plan': 'Plano de {date}: de {low} a {high}, provável {likely}.',
        'fc-now': 'Hoje: de {low} a {high}, provável {likely}. Faltam {left}% do trabalho estimado.',
        'fc-note': 'Uma estimativa, não um compromisso: fases concluídas contam inteiras, fases em andamento contam pela parte dos itens prontos.',
        'history': 'Histórico', 'history-note': 'Itens prontos em cada dia registrado.',
        'items': 'Todos os itens', 'all': 'Todos', 'search': 'Buscar', 'of': 'de', 'track': 'Frente',
        'area': 'Área', 'id': 'Id', 'no-js': 'A lista precisa de JavaScript. Os mesmos dados estão em docs/inventory.',
        'sources': 'Fontes: <code>docs/inventory</code>, <code>docs/roadmap.md</code>, <code>docs/backlog</code> e <code>docs/dashboard</code>. Gerado por <code>scripts/dashboard.py</code>.',
        'b-open': 'aberta', 'b-done': 'feita', 'b-dropped': 'descartada',
        'new': 'novo', 'kind-item': 'item', 'kind-phase': 'fase', 'kind-backlog': 'pendência',
        'months': ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto',
                   'setembro', 'outubro', 'novembro', 'dezembro'],
        'long-date': '{d} de {month} de {y}', 'decimal': ',', 'html-lang': 'pt-BR',
    },
}


# ------------------------------------------------------------ the sources

def read_tsv(path):
    """The rows of a TSV file as dicts, without the `#` lines of its header."""
    with open(path, newline='', encoding='utf-8') as f:
        lines = [line for line in f if not line.startswith('#')]
    return list(csv.DictReader(lines, delimiter='\t', quoting=csv.QUOTE_NONE))


def write_tsv(path, columns, rows):
    """Rewrites a TSV file of docs/dashboard, keeping its `#` header lines."""
    head = [line for line in path.read_text(encoding='utf-8').splitlines(keepends=True)
            if line.startswith('#')]
    with open(path, 'w', newline='', encoding='utf-8') as f:
        f.writelines(head)
        w = csv.DictWriter(f, columns, delimiter='\t', quoting=csv.QUOTE_NONE, lineterminator='\n',
                           extrasaction='ignore')
        w.writeheader()
        w.writerows(rows)


def item_state(row):
    """The state of one inventory row: one of STATES, `out` or `na`.

    An item is `done` only when its status is Done and nothing asks for a
    second look (`review` is `-`); Done with a reason to review is
    `review`, which does not count as done.
    """
    scope = row['scope'].strip()
    if scope != 'In':
        return 'out' if scope.startswith('Out') else 'na'
    status = row['status'].strip()
    if status == 'Done':
        return 'done' if row['review'].strip() in ('', '-') else 'review'
    if status not in STATUS_TO_STATE:
        sys.exit(f'{row["id"]}: unknown status "{status}" for a row in scope')
    return STATUS_TO_STATE[status]


def load_items(tracks):
    """Every row of the inventory files named in config.toml, with its track and state."""
    rows = []
    for track in tracks:
        path = ROOT / 'docs' / 'inventory' / f'{track}.tsv'
        if not path.exists():
            sys.exit(f'{path.relative_to(ROOT)}: named in config.toml but missing')
        for row in read_tsv(path):
            rows.append(row | {'track': track, 'state': item_state(row)})
    ids = collections.Counter(r['id'] for r in rows)
    twice = sorted(i for i, n in ids.items() if n > 1)
    if twice:
        sys.exit(f'inventory ids used twice: {twice}')
    return rows


def load_phases(items):
    """The phases of the roadmap table, joined with their status and rows.

    The roadmap gives the id, the name, what the phase delivers and the
    estimate; phases.tsv gives the status, the dates and the track; the
    inventory gives the rows.
    """
    status = {r['phase']: r for r in read_tsv(HERE / 'phases.tsv')}
    row_re = re.compile(r'^\| \*\*([\w.-]+)\*\* (.+?) \| (.+) \| (\d+|-) \| (.+?) \|$')
    phases = []
    for line in (ROOT / 'docs' / 'roadmap.md').read_text(encoding='utf-8').splitlines():
        m = row_re.match(line.strip())
        if not m:
            continue
        pid, name, delivers, planned_rows, estimate = m.groups()
        st = status.get(pid)
        if st is None:
            sys.exit(f'docs/dashboard/phases.tsv has no row for phase {pid} of the roadmap')
        if st['status'] not in PHASE_STATUSES:
            sys.exit(f'phase {pid}: status must be one of {PHASE_STATUSES}')
        counts = collections.Counter(i['state'] for i in items if i['phase'] == pid)
        total = sum(counts[k] for k in STATES)
        if planned_rows != '-' and int(planned_rows) != total:
            print(f'warning: the roadmap gives {planned_rows} rows to {pid}, the inventory has {total}',
                  file=sys.stderr)
        days = estimate.strip()
        phases.append({
            'id': pid, 'name': name, 'delivers': delivers,
            'days': int(days) if days.isdigit() else None,
            'status': st['status'], 'started': st.get('started', '-'), 'ended': st.get('ended', '-'),
            'track': (st.get('track') or '-').strip() or '-', 'counts': counts, 'total': total,
        })
    if not phases:
        sys.exit('docs/roadmap.md: the table of phases was not found')
    unknown = set(status) - {p['id'] for p in phases}
    if unknown:
        sys.exit(f'docs/dashboard/phases.tsv names phases the roadmap does not have: {sorted(unknown)}')
    stray = sorted({i['phase'] for i in items} - {p['id'] for p in phases} - {'done', '-', ''})
    if stray:
        sys.exit(f'the inventory names phases the roadmap does not have: {stray}')
    return phases


def load_decisions():
    """The rows of the tables of docs/decisions.md: id, date, decision and status."""
    path = ROOT / 'docs' / 'decisions.md'
    if not path.exists():
        return []
    row_re = re.compile(r'^\| (D-\d{3,}) \| (.+?) \| (.+) \| (.+?) \|$')
    rows = []
    for line in path.read_text(encoding='utf-8').splitlines():
        m = row_re.match(line.strip())
        if m:
            rows.append(dict(zip(('id', 'date', 'decision', 'status'), m.groups())))
    return rows


def assumed_decisions():
    """The decisions an agent settled and the owner has not confirmed or replaced."""
    return [d for d in load_decisions() if 'assumed' in d['status'].lower()]


def load_prs(repo, use_github):
    """The pull requests changed most recently, newest first, and where they came from."""
    if repo and use_github:
        try:
            out = subprocess.run(
                ['gh', 'api', '-X', 'GET', 'search/issues', '-f', f'q=repo:{repo} is:pr',
                 '-f', 'sort=updated', '-f', 'order=desc', '-f', 'per_page=10'],
                capture_output=True, text=True, timeout=60, check=True).stdout
            rows = []
            for it in json.loads(out)['items']:
                merged = (it.get('pull_request') or {}).get('merged_at')
                state = 'merged' if merged else it['state']
                rows.append({'number': it['number'], 'title': it['title'], 'state': state,
                             'date': (merged or it['updated_at'])[:10], 'url': it['html_url']})
            if rows:
                return rows, 'GitHub'
        except (OSError, subprocess.SubprocessError, ValueError, KeyError) as e:
            print(f'warning: GitHub did not answer ({e}); reading the merges of git', file=sys.stderr)
    try:
        out = subprocess.run(['git', '-C', str(ROOT), 'log', '--merges', '-n', '200',
                              '--format=%cs%x09%s%x09%b%x00'],
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.SubprocessError):
        return [], 'git'
    rows = []
    for entry in out.split('\0'):
        date, _, rest = entry.strip().partition('\t')
        subject, _, body = rest.partition('\t')
        m = re.match(r'Merge pull request #(\d+) ', subject)
        if m:
            title = body.strip().splitlines()[0] if body.strip() else subject
            url = f'https://github.com/{repo}/pull/{m.group(1)}' if repo else ''
            rows.append({'number': int(m.group(1)), 'title': title, 'state': 'merged', 'date': date, 'url': url})
    return rows[:10], 'git'


def forecast(phases, today):
    """The forecast, worked out from the plan and the progress.

    forecast.tsv says how many days the whole work takes: least, likely and
    most. The share still to do is measured in the estimated days of the
    phases: a phase that ended counts whole, a phase in progress counts by
    the share of its rows that are done, the others count nothing. Today's
    forecast is today plus that share of the plan's days.
    """
    plan = {r['key']: r['value'] for r in read_tsv(HERE / 'forecast.tsv')}
    base = datetime.date.fromisoformat(plan['baseline_date'])
    days = {k: int(plan[f'days_{k}']) for k in ('low', 'likely', 'high')}
    total = sum(p['days'] for p in phases if p['days'])
    earned = 0.0
    for p in phases:
        if not p['days']:
            continue
        if p['status'] == 'done':
            earned += p['days']
        elif p['status'] == 'in-progress' and p['total']:
            earned += p['days'] * p['counts']['done'] / p['total']
    left = 1 - earned / total if total else 1.0
    add = datetime.timedelta
    return {'base': base, 'left': left,
            'plan': {k: base + add(days=v) for k, v in days.items()},
            'now': {k: today + add(days=round(v * left)) for k, v in days.items()}}


def next_phases(phases):
    """The phases to work on next: the first not started of each track.

    Phases are taken in the order of the roadmap. Phases without a track
    (`-`) form one sequence of their own. A track only offers its next phase
    when every untracked phase before it is done, so a common base is
    finished before the tracks that depend on it start.
    """
    found, seen = [], set()
    for n, p in enumerate(phases):
        if p['status'] != 'not-started' or p['track'] in seen:
            continue
        before = [q for q in phases[:n] if q['track'] == '-' and q['status'] != 'done']
        if p['track'] != '-' and before:
            continue
        seen.add(p['track'])
        found.append(p)
    return found


def snapshot_now(items, phases, backlog):
    """The status of every item, phase and backlog row, keyed by kind and id."""
    snap = {('item', i['id']): i['state'] for i in items}
    snap.update({('phase', p['id']): p['status'] for p in phases})
    snap.update({('backlog', b['id']): b['status'] for b in backlog})
    return snap


def load_changes(snap, today):
    """The logged changes plus those since the last record (dated today).

    An empty snapshot is the first record: the starting point, with nothing
    counted as a change. Returns (all the changes, the ones still to record).
    """
    logged = read_tsv(HERE / 'changes.tsv')
    old = {(r['kind'], r['id']): r['state'] for r in read_tsv(HERE / 'snapshot.tsv')}
    pending = []
    if old:
        for (kind, key), state in sorted(snap.items()):
            before = old.get((kind, key), 'new')
            if before != state:
                pending.append({'date': today.isoformat(), 'kind': kind, 'id': key, 'from': before, 'to': state})
    return logged + pending, pending


# ---------------------------------------------------------------- the page

def esc(text):
    return html.escape(str(text), quote=True)


class Page:
    """Formats numbers, dates and words in the language of config.toml."""

    def __init__(self, lang):
        if lang not in LABELS:
            sys.exit(f'config.toml: language must be one of {sorted(LABELS)}')
        self.t = LABELS[lang]

    def __getitem__(self, key):
        return self.t[key]

    def num(self, value, digits=1):
        return f'{value:.{digits}f}'.replace('.', self.t['decimal'])

    def day(self, d):
        return self.t['long-date'].format(d=d.day, month=self.t['months'][d.month - 1], y=d.year)

    def state(self, s, kind='phase'):
        """The label of a status of an item, a phase or a backlog row."""
        if kind == 'backlog':
            return self.t.get('b-' + s, s)
        if kind == 'phase' and s == 'done':
            return self.t['phase-done']
        return self.t.get(s, s)


def bar(counts, labels):
    """A stacked bar of the states of a group of items."""
    total = sum(counts[k] for k in STATES) or 1
    segs = ''.join(f'<span class="seg s-{k}" style="width:{100 * counts[k] / total:.2f}%" '
                   f'title="{esc(labels[k])}: {counts[k]}"></span>' for k in STATES if counts[k])
    return f'<div class="bar" role="img" aria-label="{esc(legend_text(counts, labels))}">{segs}</div>'


def legend_text(counts, labels):
    return ', '.join(f'{labels[k]}: {counts[k]}' for k in STATES)


def legend(counts, labels):
    return '<ul class="legend">' + ''.join(
        f'<li><span class="key s-{k}"></span>{esc(labels[k])} <b>{counts[k]}</b></li>' for k in STATES) + '</ul>'


def sparkline(history):
    """An SVG line of the items done on each recorded day."""
    values = [int(r['done']) for r in history]
    if len(values) < 2:
        return ''
    top = max(values) or 1
    step = 100 / (len(values) - 1)
    pts = ' '.join(f'{n * step:.2f},{40 - 36 * v / top:.2f}' for n, v in enumerate(values))
    return (f'<svg class="spark" viewBox="0 0 100 42" preserveAspectRatio="none" role="img" '
            f'aria-label="{values[0]} → {values[-1]}"><polyline points="{pts}" fill="none" '
            f'stroke="var(--accent)" stroke-width="1.5" vector-effect="non-scaling-stroke"/></svg>'
            f'<div class="spark-ends"><span>{esc(history[0]["date"])}: {values[0]}</span>'
            f'<span>{esc(history[-1]["date"])}: {values[-1]}</span></div>')


def render(cfg, t, items, phases, backlog, prs, prs_source, history, changes, fc, today, commit,
           assumed=()):
    """The content of the page, shared by the website and the hosted fragment."""
    tracks = cfg['tracks']
    scope = [i for i in items if i['state'] in STATES]
    totals = collections.Counter(i['state'] for i in scope)
    n_scope, n_done = len(scope), totals['done']
    pct = t.num(100 * n_done / n_scope) if n_scope else '0'
    open_items = [b for b in backlog if b['status'] == 'open']
    current = [p for p in phases if p['status'] == 'in-progress']
    slip = (fc['now']['likely'] - fc['plan']['likely']).days
    labels = {k: t[k] for k in STATES}

    o = []
    w = o.append
    w('<div class="dk">')
    slip_text = (t['fc-same'] if slip == 0 else
                 t['fc-later'].format(n=slip) if slip > 0 else t['fc-earlier'].format(n=-slip))
    w(f'<header><h1>{esc(cfg["title"])}</h1><p class="lead">'
      + t['lead'].format(done=n_done, scope=n_scope, target=esc(cfg['target']), pct=pct) + ' '
      + (t['current'].format(phases=esc(', '.join(f'{p["id"]} {p["name"]}' for p in current)))
         if current else t['no-current']) + ' '
      + t['fc-lead'].format(date=t.day(fc['now']['likely']), slip=slip_text) + '</p>')
    w(f'<p class="stamp">{t["stamp"].format(date=t.day(today), commit=esc(commit))}</p></header>')

    prev = history[-2] if len(history) > 1 else None

    def since(key, now):
        if not prev:
            return ''
        return f'<div class="note">{t["k-since"].format(n=now - int(prev[key]), date=prev["date"])}</div>'

    done_phases = sum(p['status'] == 'done' for p in phases)
    w('<section class="kpis">')
    w(f'<div class="card kpi"><div class="label">{t["k-done"]}</div><div class="value">{n_done} '
      f'<small>/ {n_scope}</small></div>{since("done", n_done)}</div>')
    w(f'<div class="card kpi"><div class="label">{t["k-phase"]}</div><div class="value">{done_phases} '
      f'<small>/ {len(phases)}</small></div></div>')
    w(f'<div class="card kpi"><div class="label">{t["k-backlog"]}</div><div class="value">{len(open_items)}</div>'
      f'{since("backlog_open", len(open_items))}</div>')
    w(f'<div class="card kpi"><div class="label">{t["k-forecast"]}</div>'
      f'<div class="value small">{t.day(fc["now"]["likely"])}</div><div class="note">{esc(slip_text)}</div></div>')
    w('</section>')

    w(f'<section class="card"><h2>{t["tracks"]}</h2>{bar(totals, labels)}{legend(totals, labels)}')
    if len(tracks) > 1:
        w('<div class="tracks">')
        for key, name in tracks.items():
            c = collections.Counter(i['state'] for i in scope if i['track'] == key)
            n = sum(c[k] for k in STATES)
            share = t.num(100 * c['done'] / n) if n else '0'
            w(f'<div><h3>{esc(name)} <span class="dim">{share}%</span></h3>{bar(c, labels)}'
              f'<p class="dim small">{c["done"]} / {n}</p></div>')
        w('</div>')
    w('</section>')

    # What was just done: the latest dates of the change log, and the PRs.
    w(f'<section class="card"><h2>{t["just-done"]}</h2><h3>{t["changes"]}</h3>')
    dates = sorted({c['date'] for c in changes}, reverse=True)[:3]
    recent = [c for c in changes if c['date'] in dates]
    if recent:
        w('<ul class="plain">')
        for c in sorted(recent, key=lambda c: (c['date'], c['kind'], c['id']), reverse=True)[:40]:
            before = t['new'] if c['from'] == 'new' else t.state(c['from'], c['kind'])
            w(f'<li><span class="dim">{esc(c["date"])}</span> {esc(t["kind-" + c["kind"]])} '
              f'<b>{esc(c["id"])}</b>: {esc(before)} → {esc(t.state(c["to"], c["kind"]))}</li>')
        w('</ul>')
    else:
        w(f'<p class="dim">{t["no-changes"]}</p>')
    w(f'<h3>{t["prs"]} <span class="dim small">{t["prs-from"].format(source=prs_source)}</span></h3>')
    if prs:
        w('<ul class="plain">')
        for pr in prs:
            link = f'<a href="{esc(pr["url"])}">#{pr["number"]}</a>' if pr['url'] else f'#{pr["number"]}'
            w(f'<li>{link} {esc(pr["title"])} <span class="pill {esc(pr["state"])}">{esc(pr["state"])}</span> '
              f'<span class="dim">{esc(pr["date"])}</span></li>')
        w('</ul>')
    else:
        w(f'<p class="dim">{t["no-prs"]}</p>')
    w('</section>')

    # What comes next: phases in progress, then the next of each track.
    w(f'<section class="card"><h2>{t["next"]}</h2>')
    upcoming = current + next_phases(phases)
    if not upcoming:
        w(f'<p class="dim">{t["nothing-next"]}</p>')
    for p in upcoming:
        todo = [i for i in items if i['phase'] == p['id'] and i['state'] in STATES and i['state'] != 'done']
        back = [b for b in open_items if b['to_phase'] == p['id']]
        w(f'<div class="next"><h3>{esc(p["id"])} {esc(p["name"])} '
          f'<span class="pill {p["status"]}">{esc(t.state(p["status"]))}</span></h3>'
          f'<p class="dim">{esc(p["delivers"])}</p>')
        if todo:
            w(f'<h4>{t["to-do"]} ({len(todo)})</h4><ul class="plain">'
              + ''.join(f'<li><b>{esc(i["id"])}</b> {esc(i["item"])} <span class="dim">'
                        f'({esc(t[i["state"]])})</span></li>' for i in todo[:30]) + '</ul>')
        if back:
            w(f'<h4>{t["backlog-back"]} ({len(back)})</h4><ul class="plain">'
              + ''.join(f'<li><b>{esc(b["id"])}</b> {esc(b["item"])}</li>' for b in back) + '</ul>')
        w('</div>')
    w('</section>')

    w(f'<section class="card"><h2>{t["phases"]}</h2><div class="scroll"><table><thead><tr>'
      f'<th>{t["phase"]}</th><th>{t["delivers"]}</th><th>{t["status"]}</th><th>{t["progress"]}</th>'
      f'<th class="n">{t["days"]}</th><th>{t["dates"]}</th></tr></thead><tbody>')
    for p in phases:
        prog = (f'{bar(p["counts"], labels)}<div class="sub">{p["counts"]["done"]} / {p["total"]}</div>'
                if p['total'] else '<span class="dim">-</span>')
        dates = ' – '.join(d for d in (p['started'], p['ended']) if d and d != '-') or '-'
        w(f'<tr><td class="id">{esc(p["id"])}</td><td class="wide"><b>{esc(p["name"])}</b>'
          f'<div class="sub">{esc(p["delivers"])}</div></td>'
          f'<td><span class="pill {p["status"]}">{esc(t.state(p["status"]))}</span></td>'
          f'<td>{prog}</td><td class="n">{p["days"] if p["days"] is not None else "-"}</td>'
          f'<td class="dim">{esc(dates)}</td></tr>')
    w('</tbody></table></div></section>')

    w(f'<section class="card"><h2>{t["backlog"]}</h2>')
    if open_items:
        w(f'<div class="scroll"><table><thead><tr><th>{t["id"]}</th><th>{t["item"]}</th>'
          f'<th>{t["reason"]}</th><th>{t["from-to"]}</th></tr></thead><tbody>')
        for b in open_items:
            w(f'<tr><td class="id">{esc(b["id"])}</td><td class="wide">{esc(b["item"])}</td>'
              f'<td class="wide dim">{esc(b["reason"])}</td><td>{esc(b["from_phase"])} → '
              f'<b>{esc(b["to_phase"])}</b></td></tr>')
        w('</tbody></table></div>')
    else:
        w(f'<p class="dim">{t["no-backlog"]}</p>')
    w('</section>')

    # Shown only when there is something for the owner to confirm.
    if assumed:
        w(f'<section class="card"><h2>{t["assumed"]} ({len(assumed)})</h2>'
          f'<p class="dim small">{t["assumed-note"]}</p><div class="scroll"><table><thead><tr>'
          f'<th>{t["id"]}</th><th>{t["date"]}</th><th>{t["decision"]}</th></tr></thead><tbody>')
        for dec in assumed:
            w(f'<tr><td class="id">{esc(dec["id"])}</td><td class="dim">{esc(dec["date"])}</td>'
              f'<td class="wide">{esc(dec["decision"])}</td></tr>')
        w('</tbody></table></div></section>')

    d = t.day
    w(f'<section class="card"><h2>{t["forecast"]}</h2>'
      f'<p>{t["fc-plan"].format(date=d(fc["base"]), low=d(fc["plan"]["low"]), high=d(fc["plan"]["high"]), likely=d(fc["plan"]["likely"]))}</p>'
      f'<p>{t["fc-now"].format(low=d(fc["now"]["low"]), high=d(fc["now"]["high"]), likely=d(fc["now"]["likely"]), left=t.num(100 * fc["left"]))}</p>'
      f'<p class="dim small">{t["fc-note"]}</p></section>')

    spark = sparkline(history)
    if spark:
        w(f'<section class="card"><h2>{t["history"]}</h2><p class="dim small">{t["history-note"]}</p>{spark}</section>')

    states_all = STATES + ['out', 'na']
    opts = lambda pairs: f'<option value="">{t["all"]}</option>' + ''.join(
        f'<option value="{esc(k)}">{esc(v)}</option>' for k, v in pairs)
    w(f'<section class="card"><h2>{t["items"]}</h2><div class="filters">'
      f'<select id="dk-track" aria-label="{t["track"]}">{opts(tracks.items())}</select>'
      f'<select id="dk-phase" aria-label="{t["phase"]}">{opts((p["id"], p["id"] + " " + p["name"]) for p in phases)}</select>'
      f'<select id="dk-state" aria-label="{t["status"]}">{opts((s, t[s]) for s in states_all)}</select>'
      f'<input id="dk-q" type="search" placeholder="{t["search"]}" aria-label="{t["search"]}">'
      f'<span class="count" id="dk-count" aria-live="polite"></span></div>'
      f'<div class="scroll box"><table><thead><tr><th>{t["id"]}</th><th>{t["item"]}</th><th>{t["track"]}</th>'
      f'<th>{t["area"]}</th><th>{t["phase"]}</th><th>{t["status"]}</th></tr></thead>'
      f'<tbody id="dk-rows"></tbody></table></div><noscript><p class="dim">{t["no-js"]}</p></noscript></section>')

    w(f'<p class="foot">{t["sources"]}'
      + (f' <a href="https://github.com/{esc(cfg["repo"])}">{esc(cfg["repo"])}</a>.' if cfg.get('repo') else '')
      + (f' <a href="{esc(cfg["site"])}">{esc(cfg["site"])}</a>' if cfg.get('site') else '') + '</p>')
    w('</div>')

    data = {'tracks': tracks, 'states': {s: t[s] for s in states_all}, 'of': t['of'],
            'rows': [{k: i[k] for k in ('id', 'track', 'area', 'item', 'phase', 'state', 'note')} for i in items]}
    blob = json.dumps(data, ensure_ascii=False, separators=(',', ':')).replace('</', '<\\/')
    w(f'<script type="application/json" id="dk-data">{blob}</script><script>{JS}</script>')
    return '\n'.join(o)


CSS = """
:root {
  --window: #fafafb; --card: #ffffff; --fg: #2a2a30; --strong: #1e1e24; --dim: #63636b;
  --border: rgba(0,0,6,.12); --accent: #1c71d8; --track: rgba(0,0,6,.08);
  --s-done: #26a269; --s-review: #8ac926; --s-partial: #e5a50a; --s-started: #3584e4; --s-missing: #b8b8c0;
  --ok: #1a7f4e; --bad: #c01c28;
  --shadow: 0 0 0 1px rgba(0,0,6,.03), 0 1px 3px 1px rgba(0,0,6,.07);
  --sans: Inter, Cantarell, system-ui, -apple-system, "Segoe UI", sans-serif;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) {
  --window: #222226; --card: #2e2e32; --fg: #e8e8ec; --strong: #fff; --dim: #a8a8b0;
  --border: rgba(255,255,255,.14); --accent: #78aeed; --track: rgba(255,255,255,.1);
  --s-done: #57e389; --s-review: #b5e36b; --s-partial: #f8c84a; --s-started: #62a0ea; --s-missing: #6c6c74;
  --ok: #8ff0a4; --bad: #ff7b63; --shadow: 0 0 0 1px rgba(0,0,6,.3); color-scheme: dark; } }
:root[data-theme="dark"] {
  --window: #222226; --card: #2e2e32; --fg: #e8e8ec; --strong: #fff; --dim: #a8a8b0;
  --border: rgba(255,255,255,.14); --accent: #78aeed; --track: rgba(255,255,255,.1);
  --s-done: #57e389; --s-review: #b5e36b; --s-partial: #f8c84a; --s-started: #62a0ea; --s-missing: #6c6c74;
  --ok: #8ff0a4; --bad: #ff7b63; --shadow: 0 0 0 1px rgba(0,0,6,.3); color-scheme: dark; }
body { background: var(--window); color: var(--fg); font: 15px/1.5 var(--sans); margin: 0; padding: 28px 16px 48px; }
.dk { max-width: 1040px; margin: 0 auto; display: flex; flex-direction: column; gap: 24px; }
.dk h1 { font-size: 28px; line-height: 1.2; margin: 0; color: var(--strong); }
.dk h2 { font-size: 18px; margin: 0 0 8px; color: var(--strong); }
.dk h3 { font-size: 15px; margin: 14px 0 6px; color: var(--strong); }
.dk h4 { font-size: 13px; margin: 10px 0 4px; color: var(--dim); }
.dk p { margin: 0 0 6px; } .dk a { color: var(--accent); }
.dim { color: var(--dim); } .small { font-size: 13px; }
.lead { font-size: 17px; max-width: 75ch; margin-top: 8px !important; }
.stamp, .foot { color: var(--dim); font-size: 13px; }
.card { background: var(--card); border-radius: 12px; box-shadow: var(--shadow); padding: 16px 18px; min-width: 0; }
.kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px; }
.kpi .label, .kpi .note { color: var(--dim); font-size: 13px; }
.kpi .value { font-size: 28px; font-weight: 700; color: var(--strong); font-variant-numeric: tabular-nums; }
.kpi .value.small { font-size: 18px; padding-top: 8px; }
.kpi .value small { font-size: 15px; font-weight: 400; color: var(--dim); }
.bar { display: flex; height: 14px; border-radius: 7px; overflow: hidden; background: var(--track); gap: 1px; min-width: 100px; }
.seg { min-width: 2px; }
.s-done { background: var(--s-done); } .s-review { background: var(--s-review); } .s-partial { background: var(--s-partial); }
.s-started { background: var(--s-started); } .s-missing { background: var(--s-missing); }
.legend { list-style: none; display: flex; flex-wrap: wrap; gap: 4px 16px; padding: 0; margin: 8px 0 0; font-size: 13px; color: var(--dim); }
.legend b { color: var(--strong); }
.key { display: inline-block; width: 10px; height: 10px; border-radius: 3px; margin-right: 6px; }
.tracks { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-top: 12px; }
.scroll { overflow-x: auto; } .box { max-height: 520px; overflow-y: auto; }
.dk table { border-collapse: collapse; width: 100%; font-size: 14px; }
.dk th { text-align: left; color: var(--dim); font-size: 12px; text-transform: uppercase; letter-spacing: .03em;
  padding: 6px 10px; border-bottom: 1px solid var(--border); white-space: nowrap; }
.dk td { padding: 8px 10px; border-bottom: 1px solid var(--border); vertical-align: top; }
.dk td.n, .dk th.n { text-align: right; } .dk td.id { font-weight: 700; color: var(--strong); white-space: nowrap; }
.dk td.wide { min-width: 200px; } .dk .sub { color: var(--dim); font-size: 13px; }
.pill { display: inline-block; border-radius: 99px; padding: 1px 10px; font-size: 12px; font-weight: 600; white-space: nowrap;
  border: 1px solid var(--border); color: var(--dim); }
.pill.in-progress, .pill.open { color: var(--accent); border-color: currentColor; }
.pill.done, .pill.merged { color: var(--ok); border-color: currentColor; } .pill.closed { color: var(--bad); border-color: currentColor; }
.plain { margin: 0; padding-left: 18px; display: flex; flex-direction: column; gap: 3px; }
.next + .next { border-top: 1px solid var(--border); margin-top: 14px; }
.filters { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 10px; align-items: center; }
.filters select, .filters input { font: inherit; padding: 6px 10px; border-radius: 8px; border: 1px solid var(--border);
  background: var(--card); color: var(--fg); min-width: 0; max-width: 100%; }
.filters input { flex: 1 1 160px; } .filters .count { color: var(--dim); font-size: 13px; margin-left: auto; }
.spark { width: 100%; height: 110px; display: block; margin-top: 8px; }
.spark-ends { display: flex; justify-content: space-between; font-size: 13px; color: var(--dim); }
"""

JS = """
(function () {
  var data = JSON.parse(document.getElementById('dk-data').textContent);
  var body = document.getElementById('dk-rows'), count = document.getElementById('dk-count');
  var f = { track: document.getElementById('dk-track'), phase: document.getElementById('dk-phase'),
            state: document.getElementById('dk-state'), q: document.getElementById('dk-q') };
  function cell(tr, text, cls) { var td = document.createElement('td'); if (cls) td.className = cls; td.textContent = text; tr.appendChild(td); return td; }
  function draw() {
    var q = f.q.value.trim().toLowerCase(), n = 0, frag = document.createDocumentFragment();
    data.rows.forEach(function (r) {
      if (f.track.value && r.track !== f.track.value) return;
      if (f.phase.value && r.phase !== f.phase.value) return;
      if (f.state.value && r.state !== f.state.value) return;
      if (q && (r.id + ' ' + r.item + ' ' + r.area + ' ' + r.note).toLowerCase().indexOf(q) < 0) return;
      n += 1;
      var tr = document.createElement('tr');
      cell(tr, r.id, 'id');
      var td = cell(tr, r.item, 'wide');
      if (r.note && r.note !== '-') { var s = document.createElement('div'); s.className = 'sub'; s.textContent = r.note; td.appendChild(s); }
      cell(tr, data.tracks[r.track] || r.track); cell(tr, r.area); cell(tr, r.phase);
      var p = document.createElement('span'); p.className = 'pill'; p.textContent = data.states[r.state];
      if (r.state !== 'out' && r.state !== 'na') { var k = document.createElement('span'); k.className = 'key s-' + r.state; p.insertBefore(k, p.firstChild); }
      cell(tr, '').appendChild(p);
      frag.appendChild(tr);
    });
    body.replaceChildren(frag);
    count.textContent = n + ' ' + data.of + ' ' + data.rows.length;
  }
  Object.keys(f).forEach(function (k) { f[k].addEventListener(k === 'q' ? 'input' : 'change', draw); });
  draw();
})();
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out')
    ap.add_argument('--artifact')
    ap.add_argument('--record', action='store_true')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--date')
    ap.add_argument('--no-prs', action='store_true')
    args = ap.parse_args()

    cfg = tomllib.loads((HERE / 'config.toml').read_text(encoding='utf-8'))
    cfg.setdefault('tracks', {'main': 'Main'})
    cfg.setdefault('title', 'Dashboard')
    cfg.setdefault('target', 'the target')
    t = Page(cfg.get('language', 'en'))
    try:
        tz = zoneinfo.ZoneInfo(cfg.get('timezone') or 'UTC')
    except (zoneinfo.ZoneInfoNotFoundError, ValueError):
        sys.exit(f'config.toml: unknown timezone "{cfg.get("timezone")}"')
    today = datetime.date.fromisoformat(args.date) if args.date else datetime.datetime.now(tz).date()

    items = load_items(cfg['tracks'])
    phases = load_phases(items)
    backlog = read_tsv(ROOT / 'docs' / 'backlog' / 'deferred.tsv')
    fc = forecast(phases, today)
    if args.check:
        print(f'{len(items)} items, {len(phases)} phases, {len(backlog)} backlog rows: the sources agree')
        return
    prs, prs_source = load_prs(cfg.get('repo', ''), not args.no_prs)
    commit = subprocess.run(['git', '-C', str(ROOT), 'rev-parse', '--short', 'HEAD'],
                            capture_output=True, text=True).stdout.strip() or '-'

    totals = collections.Counter(i['state'] for i in items)
    row = {'date': today.isoformat(), 'in_scope': sum(totals[k] for k in STATES),
           **{k: totals[k] for k in STATES},
           'backlog_open': sum(b['status'] == 'open' for b in backlog),
           'forecast': fc['now']['likely'].isoformat()}
    row = {k: str(v) for k, v in row.items()}
    snap = snapshot_now(items, phases, backlog)
    changes, _ = load_changes(snap, today)
    if args.record:
        rows = [r for r in read_tsv(HERE / 'history.tsv') if r['date'] != row['date']] + [row]
        write_tsv(HERE / 'history.tsv', HISTORY_COLUMNS, sorted(rows, key=lambda r: r['date']))
        write_tsv(HERE / 'changes.tsv', ['date', 'kind', 'id', 'from', 'to'], changes)
        write_tsv(HERE / 'snapshot.tsv', ['kind', 'id', 'state'],
                  [{'kind': k, 'id': i, 'state': v} for (k, i), v in sorted(snap.items())])
    # The page always shows today as the last point, recorded or not.
    history = [r for r in read_tsv(HERE / 'history.tsv') if r['date'] < row['date']] + [row]

    content = render(cfg, t, items, phases, backlog, prs, prs_source, history, changes, fc, today, commit,
                     assumed_decisions())
    head = f'<title>{esc(cfg["title"])}</title>\n<style>{CSS}</style>'
    if args.out:
        path = pathlib.Path(args.out)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            f'<!doctype html>\n<html lang="{t["html-lang"]}">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
            '<meta name="color-scheme" content="light dark">\n'
            f'{head}\n</head>\n<body>\n{content}\n</body>\n</html>\n', encoding='utf-8')
    if args.artifact:
        path = pathlib.Path(args.artifact)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(head + '\n' + content + '\n', encoding='utf-8')
    print(f'{row["done"]} of {row["in_scope"]} items done; {row["backlog_open"]} backlog items open; '
          f'forecast {row["forecast"]}; pull requests from {prs_source}')


if __name__ == '__main__':
    main()
