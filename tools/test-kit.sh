#!/usr/bin/env bash
# Tests the kit the way it is used: makes a project from the template in a
# temporary folder, runs its checks, its state report and its dashboard,
# tries each guard on the mistake it exists for, and installs the
# user-level files in a temporary home. Run it before pushing a change to
# the kit; the CI runs it too.
#
# Usage: tools/test-kit.sh
#
# It stops at the first failure and names it. Needs bash, git and python3
# 3.11 or later; the licence check runs when `reuse` is installed.

set -euo pipefail
KIT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export GIT_AUTHOR_NAME=Tester GIT_AUTHOR_EMAIL=tester@example.invalid
export GIT_COMMITTER_NAME=Tester GIT_COMMITTER_EMAIL=tester@example.invalid

step() { printf '\n==> %s\n' "$1"; }
fail() { printf 'FAILED: %s\n' "$1" >&2; exit 1; }
# must_fail "what the guard should catch" "text expected in its message" command...
must_fail() {
    local what=$1 expect=$2 out; shift 2
    if out=$("$@" 2>&1); then fail "$what was not caught"; fi
    grep -qF -- "$expect" <<<"$out" || fail "$what was caught, but the message lacks \"$expect\": $out"
    echo "caught: $what"
}
has() { grep -qF -- "$2" <<<"$1" || fail "expected \"$2\" in: $1"; }

step 'The copies of the skills and the rules are in step'
python3 "$KIT/tools/build-kit.py" --check
python3 - "$KIT" <<'PY'
import json, pathlib, re, sys
kit = pathlib.Path(sys.argv[1])
skills = sorted(p.name for p in (kit / 'project-template/.claude/skills').iterdir() if (p / 'SKILL.md').is_file())
problems = []
for name in skills:
    text = (kit / 'project-template/.claude/skills' / name / 'SKILL.md').read_text(encoding='utf-8')
    m = re.match(r'---\nname: (.+)\ndescription: (.+)\n---\n', text)
    if not m or m.group(1) != name:
        problems.append(f'{name}: the header must give name: {name} and a description on one line')
    elif not m.group(2).startswith('Use ') or len(m.group(2)) > 1024:
        problems.append(f'{name}: the description must start with "Use" and stay under 1024 characters')
    if len(text.splitlines()) > 70:
        problems.append(f'{name}: longer than 70 lines; move detail to a page of docs')
# Every skill is named where an agent or the owner learns that it exists.
for page in ('project-template/AGENTS.md', 'README.md', 'LEIA-ME.md', 'desktop/project-instructions.md'):
    text = (kit / page).read_text(encoding='utf-8')
    problems += [f'{page} does not name the skill {name}' for name in skills if name not in text]
count = (kit / 'project-template/TEMPLATE.md').read_text(encoding='utf-8')
words = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven',
         'twelve', 'thirteen', 'fourteen', 'fifteen']
if f'{words[len(skills)]} skills' not in count:
    problems.append(f'project-template/TEMPLATE.md does not say "{words[len(skills)]} skills"')
json.loads((kit / 'project-template/.claude/settings.json').read_text(encoding='utf-8'))
version = re.search(r'\| Kit version \| (\S+) \|', (kit / 'project-template/docs/kit.md').read_text(encoding='utf-8'))
history = (kit / 'HISTORY.md').read_text(encoding='utf-8')
if not version or f'## Changes in {version.group(1)} ' not in history:
    problems.append('the kit version of project-template/docs/kit.md has no heading in HISTORY.md')
size = len((kit / 'project-template/AGENTS.md').read_bytes())
if size > 12000:
    problems.append(f'project-template/AGENTS.md is {size} bytes; it is read every session, keep it under 12000')
if problems:
    sys.exit('\n'.join(problems))
print(f'{len(skills)} skills named everywhere; kit version {version.group(1)}; AGENTS.md {size} bytes')
PY

step 'Before it is initialised, the template says so and its pages agree'
cp -R "$KIT/project-template" "$WORK/acme"
cd "$WORK/acme"
has "$(python3 scripts/status.py)" 'STATE: NOT STARTED'
has "$(python3 scripts/status.py)" 'init-project.sh is still at the root'
python3 scripts/check-docs.py

step 'init-project.sh fills everything without asking'
git init -q -b main
git remote add origin https://github.com/ana/acme.git
./init-project.sh --summary 'a tool that tests the kit' --owner Ana --owner-lang 'Brazilian Portuguese' \
    --dashboard-lang pt-BR --timezone America/Sao_Paulo --license MIT </dev/null >"$WORK/init.log" \
    || { cat "$WORK/init.log"; fail 'init-project.sh'; }
[ ! -e init-project.sh ] && [ ! -e TEMPLATE.md ] || fail 'init-project.sh did not delete itself and TEMPLATE.md'
! grep -rIlE --exclude-dir=.git '(^|[^$])\{\{[A-Z_]+\}\}' . || fail 'placeholders are left'
has "$(cat README.md)" '# acme'                             # the name of the folder
has "$(cat docs/dashboard/config.toml)" 'repo = "ana/acme"'   # the origin remote
[ -L .agents/skills ] && [ -f .agents/skills/start-project/SKILL.md ] || fail 'the Codex skills link'
[ -L .pi/skills ] && [ -f .gemini/settings.json ] && [ -f .cursor/rules/project.mdc ] \
    && [ -f .github/copilot-instructions.md ] || fail 'the files of the other agents'
has "$(python3 scripts/status.py)" 'the project has no goals, inventory or roadmap yet'
scripts/check-all.sh >"$WORK/check.log" 2>&1 || { cat "$WORK/check.log"; fail 'check-all.sh on a new project'; }
tail -n 1 "$WORK/check.log"

step 'A project under way: the state report and the dashboard'
# What start-project does last: the "not started" section goes.
python3 - <<'PY'
import pathlib, re
p = pathlib.Path('AGENTS.md')
text = re.sub(r'<!-- kit:not-started begin -->.*?<!-- kit:not-started end -->\n\n', '', p.read_text(), flags=re.S)
assert 'not-started' not in text
p.write_text(text)
PY
python3 scripts/dashboard.py --record --no-prs --out "$WORK/site/index.html" --artifact "$WORK/site/fragment.html"
git add -A && git commit -qm 'Start the project'
git update-ref refs/remotes/origin/main HEAD
state=$(python3 scripts/status.py)
echo "$state"
has "$state" 'Phase in progress: P0 Planning'
has "$state" 'Rules: AGENTS.md'
[ "$(wc -l <<<"$state")" -le 30 ] || fail 'the state report is longer than 30 lines'
scripts/check-all.sh >"$WORK/check.log" 2>&1 || { cat "$WORK/check.log"; fail 'check-all.sh on a project under way'; }

step 'Each guard catches the mistake it exists for'
# A status changed and nothing was recorded.
sed -i 's/^F-003\tCore\t\(.*\)\tIn\tMissing/F-003\tCore\t\1\tIn\tDone/' docs/inventory/main.tsv
must_fail 'a change of status that was not recorded' 'are not recorded (F-003)' python3 scripts/check-records.py
has "$(python3 scripts/status.py)" '1 changes of status are not recorded yet'
python3 scripts/dashboard.py --record --no-prs >/dev/null
must_fail 'a change without its HISTORY line' 'HISTORY.md has no line' python3 scripts/check-records.py
must_fail 'a change without its project log entry' 'docs/project-log.md has no entry' python3 scripts/check-records.py
echo '* Changed: F-003 is done.' >>HISTORY.md
printf '\n### 2026-11-16: F-003\n\n- F-003 is done.\n' >>docs/project-log.md
python3 scripts/check-records.py
# Pages that stopped agreeing.
cp docs/goals.md "$WORK/goals.md"
echo 'See [the plan](missing-page.md) and D-999.' >>docs/goals.md
must_fail 'a link to a page that does not exist' 'the link to missing-page.md leads nowhere' python3 scripts/check-docs.py
must_fail 'a decision cited but never recorded' 'D-999 is cited' python3 scripts/check-docs.py
cp "$WORK/goals.md" docs/goals.md
cp docs/decisions.md "$WORK/decisions.md"
sed -i 's/^| D-002 | \(.*\) | Current |$/| D-002 | \1 | Maybe |/' docs/decisions.md
must_fail 'a decision with an unknown status' 'D-002 has the status "Maybe"' python3 scripts/check-docs.py
cp "$WORK/decisions.md" docs/decisions.md
echo 'A {{'PROJECT_NAME'}} left behind.' >>docs/roadmap.md
must_fail 'a placeholder left after the start' 'a placeholder of the template is left' python3 scripts/check-docs.py
sed -i '$d' docs/roadmap.md
python3 scripts/check-docs.py
# A phase with open backlog cannot close.
must_fail 'closing a phase with open backlog' 'still open' python3 scripts/check-backlog.py --phase P1

step 'Decisions assumed and lessons without a guard reach the owner and the agent'
sed -i 's/^| D-003 | \(.*\) | Current |$/| D-003 | \1 | Current (assumed, not contested) |/' docs/decisions.md
sed -i 's/^| L-001 | \(.*\) | guarded |$/| L-001 | \1 | open |/' docs/lessons.md
state=$(python3 scripts/status.py)
has "$state" 'Decisions assumed and not yet confirmed by the owner: D-003'
has "$state" 'Lessons without a guard yet: L-001'
python3 scripts/check-docs.py
python3 scripts/dashboard.py --no-prs --out "$WORK/site/index.html" >/dev/null
has "$(cat "$WORK/site/index.html")" 'Decisões aguardando o dono (1)'

step 'A source that disagrees is reported, and the session still starts'
sed -i 's/^P2\tnot-started/P9\tnot-started/' docs/dashboard/phases.tsv
has "$(python3 scripts/status.py)" 'STATE: THE SOURCES DISAGREE'
git checkout -q docs/dashboard/phases.tsv

step 'Another choice of agents, with copies instead of links'
cp -R "$KIT/project-template" "$WORK/solo"
(cd "$WORK/solo" && ./init-project.sh --name Solo --tools claude,codex --copy </dev/null >/dev/null \
    && [ -d .agents/skills ] && [ ! -L .agents/skills ] && [ ! -e .pi ] && [ ! -e .cursor ] \
    && python3 scripts/check-docs.py >/dev/null) || fail 'init-project.sh --tools claude,codex --copy'
echo 'ok'

step 'The user-level files install, and a second run changes nothing but the rules'
export HOME="$WORK/home"
mkdir -p "$HOME/.claude" && echo 'My own notes.' >"$HOME/.claude/CLAUDE.md"
"$KIT/user-level/install-user.sh" --owner Ana --owner-lang 'Brazilian Portuguese' --dashboard-lang pt-BR \
    --timezone America/Sao_Paulo --license MIT --github ana </dev/null >/dev/null
"$KIT/user-level/install-user.sh" </dev/null >"$WORK/second.log"
for file in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"; do
    [ "$(grep -c 'working rules, begin' "$file")" = 1 ] || fail "the rules are not exactly once in $file"
    [ "$(grep -c 'owner defaults, begin' "$file")" = 1 ] || fail "the defaults are not exactly once in $file"
    has "$(cat "$file")" 'Time zone: America/Sao_Paulo'
done
has "$(cat "$HOME/.claude/CLAUDE.md")" 'My own notes.'
has "$(cat "$WORK/second.log")" 'kept yours'
[ -f "$HOME/.claude/skills/capture-lesson/SKILL.md" ] || fail 'the skills were not copied'
echo 'ok'

printf '\nThe kit works.\n'
