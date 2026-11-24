#!/usr/bin/env python3
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}
"""Turns the result of the automatic review of a pull request into its comment.

Usage: scripts/review-report.py RESULT.json --out COMMENT.md
           [--repo owner/name] [--commit SHA] [--secret-env NAME ...]

Run it from the root of the repository. The workflow runs the copy of
this script on the base branch, not the one in the pull request, so that
a pull request cannot change how it is judged.

.github/workflows/review.yml has a model read the change and return what
it found as JSON: a summary and a list of findings, each with a severity
(`blocking`, `should-fix`, `suggestion`), a category (`bug`, `security`,
`performance`, `rules`), the file and line, the problem and the fix. This
script checks that JSON, writes the comment the workflow posts on the pull
request, and says by its exit status whether the change may be merged:

    0  nothing blocks the merge (there may be findings to read)
    1  at least one finding is blocking: the check fails
    2  the result is not usable, or holds a secret: the check fails, and
       the comment says so without the result

The JSON comes from a model that read text anyone can put in a pull
request, so it is treated as untrusted input (docs/engineering.md): its
shape is checked; HTML, mentions, links, images and code fences are
neutralised, so that nothing in the comment fetches an outside address;
a file path is linked only when it is a plain relative path; and the
result is refused when it holds the value of a secret named with
--secret-env, so that a key the model was led to read is never posted.

The words of the comment are in the language of docs/dashboard/config.toml;
the model writes the summary and the findings in the owner's language.
"""
import argparse
import json
import os
import pathlib
import re
import sys
import tomllib

MARKER = '<!-- automatic-review -->'    # how the workflow finds its comment to update it
SEVERITIES = ['blocking', 'should-fix', 'suggestion']
CATEGORIES = ['bug', 'security', 'performance', 'rules']
SAFE_PATH = re.compile(r'[A-Za-z0-9_.][A-Za-z0-9_./-]*')
LIMIT = 4000                             # characters kept of one text, so a runaway answer stays readable

LABELS = {
    'en': {
        'title': 'Automatic review',
        'pass': 'passed: nothing to fix',
        'notes': 'passed, with points to read',
        'blocked': 'blocked: fix before merging',
        'unusable': 'failed: the review returned no usable result',
        'secret': 'failed: the result was withheld because it held a secret',
        'blocking': 'Must be fixed before merging',
        'should-fix': 'Should be fixed',
        'suggestion': 'Suggestions',
        'bug': 'Bug', 'security': 'Security', 'performance': 'Performance', 'rules': 'Project rules',
        'fix': 'Fix',
        'footer': 'Commit {commit}. The review runs again on every push; a finding you judge wrong is '
                  'answered in the pull request with the reason.',
        'unusable-body': 'The check failed so that the change is not merged unreviewed. Run the workflow '
                         'again; if it fails again, read its log.',
    },
    'pt-BR': {
        'title': 'Revisão automática',
        'pass': 'aprovada: nada a corrigir',
        'notes': 'aprovada, com pontos para ler',
        'blocked': 'bloqueada: corrija antes do merge',
        'unusable': 'falhou: a revisão não devolveu um resultado utilizável',
        'secret': 'falhou: o resultado foi retido porque continha um segredo',
        'blocking': 'Precisa ser corrigido antes do merge',
        'should-fix': 'Deveria ser corrigido',
        'suggestion': 'Sugestões',
        'bug': 'Bug', 'security': 'Segurança', 'performance': 'Desempenho', 'rules': 'Regras do projeto',
        'fix': 'Correção',
        'footer': 'Commit {commit}. A revisão roda de novo a cada push; um apontamento que você julgar '
                  'errado é respondido no pull request, com o motivo.',
        'unusable-body': 'A verificação falhou para que a mudança não entre sem revisão. Rode o workflow '
                         'de novo; se falhar outra vez, leia o log.',
    },
}


def language():
    """The language of the comment: the dashboard's, or English when it has none we know."""
    try:
        config = tomllib.loads(pathlib.Path('docs/dashboard/config.toml').read_text(encoding='utf-8'))
    except (OSError, tomllib.TOMLDecodeError):
        return 'en'
    lang = config.get('language', 'en')
    return lang if lang in LABELS else 'en'


def clean(text):
    """Untrusted prose made safe for a GitHub comment.

    HTML is escaped; the characters that open a link, an image, a code span,
    a code fence or emphasis are escaped with a backslash, so that a URL in
    the text stays text and nothing is fetched when the comment is shown;
    mentions get a zero-width space so that they notify nobody; and the
    length is capped.
    """
    text = re.sub(r'[\x00-\x08\x0b-\x1f\x7f]', '', str(text)).strip()
    if len(text) > LIMIT:
        text = text[:LIMIT] + ' […]'
    text = re.sub(r'([\\`\[\]()!*_~|#])', r'\\\1', text)
    return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('@', '@​')


def secrets(names):
    """The values of the environment variables named, long enough to be a real secret."""
    return [v for v in (os.environ.get(n, '') for n in names) if len(v) >= 8]


def parse(raw):
    """The review as (summary, findings), or a ValueError that says what is wrong with it."""
    data = json.loads(raw)
    if not isinstance(data, dict) or not isinstance(data.get('summary'), str) \
            or not isinstance(data.get('findings'), list):
        raise ValueError('expected an object with "summary" (text) and "findings" (list)')
    findings = []
    for n, f in enumerate(data['findings'], 1):
        if not isinstance(f, dict):
            raise ValueError(f'finding {n} is not an object')
        if f.get('severity') not in SEVERITIES:
            raise ValueError(f'finding {n} has the severity {f.get("severity")!r}, not one of {SEVERITIES}')
        if f.get('category') not in CATEGORIES:
            raise ValueError(f'finding {n} has the category {f.get("category")!r}, not one of {CATEGORIES}')
        for key in ('file', 'problem', 'fix'):
            if not isinstance(f.get(key), str):
                raise ValueError(f'finding {n} has no text for "{key}"')
        line = f.get('line')
        if line is not None and (isinstance(line, bool) or not isinstance(line, int) or line < 1):
            raise ValueError(f'finding {n} has the line {line!r}, not a positive number')
        findings.append(f)
    return data['summary'], findings


def where(f, repo, commit):
    """The file and line of a finding, linked to the reviewed commit when the path is safe to link."""
    path, line = f['file'].strip(), f.get('line')
    if not SAFE_PATH.fullmatch(path) or '..' in path.split('/'):
        return f'`{clean(path).replace("`", "")}`' if path else ''
    label = f'{path}:{line}' if line else path
    if repo and commit:
        return f'[`{label}`](https://github.com/{repo}/blob/{commit}/{path}{f"#L{line}" if line else ""})'
    return f'`{label}`'


def render(summary, findings, t, repo, commit):
    """The markdown of the comment, and whether a finding blocks the merge."""
    blocked = any(f['severity'] == 'blocking' for f in findings)
    state = 'blocked' if blocked else 'notes' if findings else 'pass'
    icon = {'blocked': '❌', 'notes': '⚠️', 'pass': '✅'}[state]
    out = [MARKER, f'## {icon} {t["title"]}: {t[state]}', '', clean(summary)]
    for severity in SEVERITIES:
        group = [f for f in findings if f['severity'] == severity]
        if not group:
            continue
        out += ['', f'### {t[severity]} ({len(group)})', '']
        for n, f in enumerate(group, 1):
            place = where(f, repo, commit)
            out.append(f'{n}. **{t[f["category"]]}**{" " + place if place else ""}: {clean(f["problem"])}')
            out.append(f'   {t["fix"]}: {clean(f["fix"])}')
    out += ['', f'<sub>{t["footer"].format(commit=(commit or "?")[:12])}</sub>', '']
    return '\n'.join(out), blocked


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('result', type=pathlib.Path)
    parser.add_argument('--out', type=pathlib.Path, required=True)
    parser.add_argument('--repo', default='')
    parser.add_argument('--commit', default='')
    parser.add_argument('--secret-env', action='append', default=[], metavar='NAME',
                        help='an environment variable whose value must never appear in the comment')
    args = parser.parse_args()
    t = LABELS[language()]

    def refuse(state, why):
        """Writes the comment of a review that cannot be posted, and fails the check."""
        args.out.write_text(f'{MARKER}\n## ❌ {t["title"]}: {t[state]}\n\n{t["unusable-body"]}\n',
                            encoding='utf-8')
        print(f'review-report: {why}', file=sys.stderr)
        return 2

    hidden = secrets(args.secret_env)
    try:
        raw = args.result.read_text(encoding='utf-8')
    except OSError as e:
        return refuse('unusable', f'the review result cannot be read: {e}')
    if any(s in raw for s in hidden):
        return refuse('secret', 'the review result holds the value of a secret; nothing of it is posted')
    try:
        summary, findings = parse(raw)
    except ValueError as e:                   # json.JSONDecodeError is a ValueError
        return refuse('unusable', f'the review result is not usable: {e}')
    body, blocked = render(summary, findings, t, args.repo, args.commit)
    if any(s in body for s in hidden):
        return refuse('secret', 'the comment would hold the value of a secret; nothing of it is posted')
    args.out.write_text(body, encoding='utf-8')
    counts = ', '.join(f'{sum(f["severity"] == s for f in findings)} {s}' for s in SEVERITIES)
    print(f'review-report: {counts}; {"the merge is blocked" if blocked else "nothing blocks the merge"}')
    return 1 if blocked else 0


if __name__ == '__main__':
    sys.exit(main())
