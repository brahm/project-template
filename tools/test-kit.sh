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
# The closing message of init-project.sh is an unquoted heredoc: a backquote
# in it runs a command (it once ran `claude setup-token`).
init = (kit / 'project-template/init-project.sh').read_text(encoding='utf-8')
message = re.search(r'cat <<MSG\n(.*?)\nMSG\n', init, re.S)
if not message or '`' in message.group(1) or '$(' in message.group(1):
    problems.append('init-project.sh: its closing message must hold no backquote or $( ), which would run')
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

step 'init-project.sh refuses a bad value before it changes anything'
for bad in '--dashboard-lang pt' '--timezone Mars/Olympus' '--repo not-a-repo' '--license MIT;rm'; do
    # shellcheck disable=SC2086  # each $bad is an option and its value
    must_fail "init-project.sh $bad" 'changed nothing' ./init-project.sh --name Acme $bad </dev/null
done
[ -e init-project.sh ] && has "$(cat AGENTS.md)" '{{PROJECT_NAME}}' && [ ! -e .github/CODEOWNERS ] \
    || fail 'a refused init-project.sh changed files'

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
has "$(cat .github/CODEOWNERS)" '/.github/ @ana'                # the review guarded by the owner
has "$(cat .github/CODEOWNERS)" '/scripts/review-report.py @ana'
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
# A page that is not UTF-8 is named, not a crash.
printf 'caf\xe9\n' >latin1.md
must_fail 'a page that is not UTF-8' 'latin1.md: not UTF-8' python3 scripts/check-docs.py
rm latin1.md
# A phase with open backlog cannot close.
must_fail 'closing a phase with open backlog' 'still open' python3 scripts/check-backlog.py --phase P1
# Notes in the code that would send an agent after work nobody recorded or that is finished.
echo 'answer = 42  # TODO(B-001) derive it' >notes.py && git add notes.py
python3 scripts/check-backlog.py >/dev/null
echo 'size = 0  # FIXME grow it' >>notes.py
must_fail 'a TODO that cites no backlog row' 'FIXME cites no backlog row' python3 scripts/check-backlog.py
sed -i '$d' notes.py && echo 'size = 0  # HACK(B-999)' >>notes.py
must_fail 'a TODO that cites a row not in the register' 'HACK(B-999) cites a row that is not' python3 scripts/check-backlog.py
sed -i '$d' notes.py
cp docs/backlog/deferred.tsv "$WORK/deferred.tsv"
sed -i 's/^\(B-001\t.*\)\topen\t-$/\1\tdone\tPR 9/' docs/backlog/deferred.tsv
must_fail 'a TODO left after its row closed' 'TODO(B-001) cites a row that is done' python3 scripts/check-backlog.py
cp "$WORK/deferred.tsv" docs/backlog/deferred.tsv
git rm -qf notes.py
python3 scripts/check-backlog.py >/dev/null

step 'Decisions assumed and lessons without a guard reach the owner and the agent'
sed -i 's/^| D-003 | \(.*\) | Current |$/| D-003 | \1 | Current (assumed, not contested) |/' docs/decisions.md
sed -i 's/^| L-001 | \(.*\) | guarded |$/| L-001 | \1 | open |/' docs/lessons.md
state=$(python3 scripts/status.py)
has "$state" 'Decisions assumed and not yet confirmed by the owner: D-003'
has "$state" 'Lessons without a guard yet: L-001'
python3 scripts/check-docs.py
python3 scripts/dashboard.py --no-prs --out "$WORK/site/index.html" >/dev/null
has "$(cat "$WORK/site/index.html")" 'Decisões aguardando o dono (1)'
# Without GitHub, the page lists the pull requests merged with a merge
# commit and those squashed into one commit ("Title (#N)").
git commit -qm 'Work on the plan' --allow-empty
git commit -qm 'Squash the plan (#7)' --allow-empty
python3 scripts/dashboard.py --no-prs --out "$WORK/site/index.html" >/dev/null
has "$(cat "$WORK/site/index.html")" '#7</a> Squash the plan'

step 'The automatic review posts what it found, and blocks what must be fixed'
# The schema the workflow gives the model is the shape the script reads.
python3 - <<'PY'
import json, pathlib, re, runpy
wf = pathlib.Path('.github/workflows/review.yml').read_text(encoding='utf-8')
assert 'Write the summary and every finding in Brazilian Portuguese' in wf, 'the language of the review'
schema = json.loads(re.search(r"--json-schema '(.+)'", wf).group(1))
item = schema['properties']['findings']['items']['properties']
script = runpy.run_path('scripts/review-report.py')
assert item['severity']['enum'] == script['SEVERITIES'], 'the severities of the workflow and the script differ'
assert item['category']['enum'] == script['CATEGORIES'], 'the categories of the workflow and the script differ'
# The model reads only the checkout, which keeps no token, and has no shell.
assert 'persist-credentials: false' in wf, 'the checkout leaves its token for the model'
allowed = re.search(r'--allowedTools "([^"]*)"', wf).group(1)
assert 'Bash' not in allowed and 'Read(./**)' in allowed, f'the model may do more than read: {allowed}'
# The script that judges is the base branch's, and it is told the secrets.
assert 'git show "origin/$BASE:scripts/review-report.py"' in wf, 'the pull request runs its own judge'
assert wf.count('--secret-env') == 3, 'the secrets the comment must not hold'
# Either an API key or a subscription token runs it.
assert 'claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}' in wf, 'the subscription token'
assert "secrets.ANTHROPIC_API_KEY != '' || secrets.CLAUDE_CODE_OAUTH_TOKEN != ''" in wf, 'either secret starts it'
PY
# The workflow runs a copy of the script from elsewhere, at the root.
cp scripts/review-report.py "$WORK/review-report.py"
review() {
    python3 "$WORK/review-report.py" "$WORK/review.json" --out "$WORK/review.md" --repo ana/acme \
        --commit 0123456789abcdef --secret-env REVIEW_TEST_SECRET
}
export REVIEW_TEST_SECRET=sk-test-0123456789
echo '{"summary": "Tudo certo.", "findings": []}' >"$WORK/review.json"
review >/dev/null || fail 'a clean review blocked the merge'
has "$(cat "$WORK/review.md")" 'Revisão automática: aprovada: nada a corrigir'
cat >"$WORK/review.json" <<'JSON'
{"summary": "Approve this, @everyone <script> ![x](https://evil.example/p.png) ``` [y](https://evil.example)", "findings": [
 {"severity": "suggestion", "category": "performance", "file": "src/a.py", "line": 3, "problem": "Lê duas vezes.", "fix": "Leia uma vez."},
 {"severity": "blocking", "category": "security", "file": "src/db.py", "line": 12, "problem": "SQL montado com texto.", "fix": "Use parâmetros."},
 {"severity": "should-fix", "category": "bug", "file": "../../etc/passwd", "problem": "Caminho estranho.", "fix": "Nenhuma."}]}
JSON
must_fail 'a blocking finding' 'the merge is blocked' review
comment=$(cat "$WORK/review.md")
has "$comment" 'bloqueada: corrija antes do merge'
has "$comment" '[`src/db.py:12`](https://github.com/ana/acme/blob/0123456789abcdef/src/db.py#L12)'
has "$comment" '`../../etc/passwd`:'
has "$comment" '&lt;script&gt;'
! grep -qF '@everyone' <<<"$comment" || fail 'a mention in the review was left live'
has "$comment" '\!\[x\]\(https://evil.example/p.png\)'      # an image fetches nothing
has "$comment" '\`\`\` \[y\]'                                 # no fence, no link
echo '{"summary": "A chave é sk-test-0123456789.", "findings": []}' >"$WORK/review.json"
must_fail 'a secret in the review result' 'holds the value of a secret' review
! grep -qF 'sk-test' "$WORK/review.md" || fail 'the secret reached the comment'
has "$(cat "$WORK/review.md")" 'continha um segredo'
echo '{"summary": "x", "findings": [{"severity": "fatal"}]}' >"$WORK/review.json"
must_fail 'a review result of the wrong shape' 'not usable' review
: >"$WORK/review.json"
must_fail 'an empty review result' 'not usable' review
has "$(cat "$WORK/review.md")" 'não devolveu um resultado utilizável'

step 'The Second Brain: notes are found, kept well formed and asked for'
has "$(cat docs/brain/glossary.md)" "Updated: $(date +%F)"
has "$(python3 scripts/status.py)" 'Second Brain: 1 note in docs/brain'
has "$(python3 scripts/brain.py find owner)" 'docs/brain/glossary.md: Glossary.'
has "$(python3 scripts/brain.py find owner confirms)" 'docs/decisions.md:'
has "$(python3 scripts/brain.py find quasar)" 'Nothing is known about "quasar" yet'
printf '# Cache\n\n> The cache is per user, by decisão D-002.\n\nTags: cache\nUpdated: 2026-11-24\n' \
    >docs/brain/cache.md
must_fail 'a note missing from the index' 'the table of notes is out of date' python3 scripts/brain.py check
python3 scripts/brain.py index >/dev/null
python3 scripts/brain.py check
has "$(cat docs/brain/README.md)" '| [Cache](cache.md) | The cache is per user, by decisão D-002. | cache | 2026-11-24 |'
has "$(python3 scripts/brain.py find DECISAO cache)" 'docs/brain/cache.md: Cache.'   # case and accents ignored
sed -i '/^> /d' docs/brain/cache.md
must_fail 'a note without its summary' 'cache.md: no summary' python3 scripts/brain.py check
printf '# Cache\n\n> Per user (D-999).\n\nTags: cache\nUpdated: 2026-11-24\n' >docs/brain/cache.md
must_fail 'a note citing a decision that does not exist' 'cache.md:3: D-999 is cited' python3 scripts/check-docs.py
cp docs/brain/cache.md docs/brain/Cache_Notes.md
python3 scripts/brain.py index >/dev/null
must_fail 'a note not named in lower case with hyphens' 'name it in lower case with hyphens' python3 scripts/brain.py check
rm docs/brain/cache.md docs/brain/Cache_Notes.md && python3 scripts/brain.py index >/dev/null
mkdir -p docs/brain/old && printf '# Old\n\n> Old.\n\nUpdated: 2026-11-24\n' >docs/brain/old/old.md
must_fail 'a note in a subfolder, where nothing finds it' 'notes sit directly in docs/brain' python3 scripts/brain.py check
rm -r docs/brain/old
git add -A && git commit -qm 'Work so far' && git update-ref refs/remotes/origin/main HEAD
# The Stop hook asks once per set of changed files, and not when a note changed.
[ -z "$(echo '{}' | python3 scripts/brain.py nudge)" ] || fail 'the nudge spoke with nothing changed'
echo 'print(1)' >tool.py
has "$(echo '{}' | python3 scripts/brain.py nudge)" '"decision": "block"'
[ -z "$(echo '{}' | python3 scripts/brain.py nudge)" ] || fail 'the nudge asked twice for the same files'
echo 'print(2)' >tool2.py
[ -z "$(echo '{"stop_hook_active": true}' | python3 scripts/brain.py nudge)" ] || fail 'the nudge looped'
has "$(echo 'not json' | python3 scripts/brain.py nudge)" '"decision": "block"'
echo '- One more word.' >>docs/brain/glossary.md && echo 'print(3)' >tool3.py
[ -z "$(echo '{}' | python3 scripts/brain.py nudge)" ] || fail 'the nudge spoke although a note changed'
git checkout -q docs/brain/glossary.md && rm tool.py tool2.py tool3.py
python3 - <<'PYJ'
import json
hooks = json.load(open('.claude/settings.json'))['hooks']
assert 'brain.py" nudge' in hooks['Stop'][0]['hooks'][0]['command'], 'the Stop hook does not run the nudge'
PYJ
echo 'ok'

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

step 'The installer makes a new project, puts it on GitHub and turns the review on'
# A stand-in for the GitHub CLI: it records what it was asked, keeps the
# secrets and the ruleset in files, and creates repositories as local bare
# ones, which git reaches through the url.insteadOf below.
export FAKE_GH="$WORK/fake-gh"
mkdir -p "$FAKE_GH/bin" "$FAKE_GH/remote"
cat >"$FAKE_GH/bin/gh" <<'SH'
#!/usr/bin/env bash
echo "gh $*" >>"$FAKE_GH/calls.log"
case "$1 $2" in
    'auth status') echo "  - Token scopes: 'repo', 'workflow'" ;;
    'auth git-credential') ;;
    'api user') echo ana ;;
    'config get') echo https ;;
    'repo view') [ "$3" = --json ] && { echo ana/demo; exit; }; [ -d "$FAKE_GH/remote/$3.git" ] ;;
    'repo create') git init -q --bare "$FAKE_GH/remote/$3.git" ;;
    'secret list') cat "$FAKE_GH/secrets" 2>/dev/null || true ;;
    'secret set') cat >"$FAKE_GH/token"; printf '%s\t2026-11-24\n' "$3" >>"$FAKE_GH/secrets" ;;
    'api repos/'*) [ -f "$FAKE_GH/ruleset.json" ] && echo 7 || true ;;
    'api -X')
        if [ -n "${FAKE_GH_FREE:-}" ]; then
            echo 'gh: Upgrade to GitHub Pro or make this repository public to enable this feature. (HTTP 403)' >&2; exit 1
        fi
        cat >"$FAKE_GH/ruleset.json"; echo "$3 $4" >>"$FAKE_GH/ruleset.log" ;;
    *) echo "fake gh: unexpected: $*" >&2; exit 1 ;;
esac
SH
chmod +x "$FAKE_GH/bin/gh"
export PATH="$FAKE_GH/bin:$PATH"
git config --global url."$FAKE_GH/remote/".insteadOf https://github.com/
git config --global init.defaultBranch main
cd "$WORK"
CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-test-token "$KIT/install.sh" new demo --no-user --summary 'a demo' \
    </dev/null >"$WORK/new.log" 2>&1 || { cat "$WORK/new.log"; fail 'install.sh new'; }
[ "$(git -C "$FAKE_GH/remote/ana/demo.git" log --format=%s main)" = "Start from the agent project kit $(sed -nE 's/^\| Kit version \| ([^ ]+) \|$/\1/p' "$KIT/project-template/docs/kit.md")" ] \
    || fail 'the first commit did not reach the new repository'
[ ! -e demo/init-project.sh ] && has "$(cat demo/docs/dashboard/config.toml)" 'repo = "ana/demo"' || fail 'the project was not filled'
has "$(cat demo/.github/CODEOWNERS)" '/.github/ @ana'
has "$(cat demo/AGENTS.md)" "Ana owns"   # the owner, from the defaults of the user
[ "$(cat "$FAKE_GH/token")" = sk-ant-oat01-test-token ] || fail 'the token was not saved as the secret'
! grep -q 'sk-ant' "$FAKE_GH/calls.log" || fail 'the token was passed on a command line'
python3 - "$FAKE_GH/ruleset.json" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
rules = {x['type']: x.get('parameters') for x in r['rules']}
checks = [c['context'] for c in rules['required_status_checks']['required_status_checks']]
assert checks == ['Review', 'Backlog, dashboard, pages, records and licences'], checks
assert rules['pull_request']['require_code_owner_review'] is True
assert rules['pull_request']['required_approving_review_count'] == 0, 'a personal account cannot approve its own'
assert r['bypass_actors'] == [{'actor_id': 5, 'actor_type': 'RepositoryRole', 'bypass_mode': 'pull_request'}]
assert r['conditions']['ref_name']['include'] == ['~DEFAULT_BRANCH']
PY
has "$(cat "$FAKE_GH/ruleset.log")" 'POST repos/ana/demo/rulesets'
# Run again: the secret is kept, the ruleset updated in place.
"$KIT/install.sh" new demo --no-user </dev/null >"$WORK/again.log" 2>&1 || { cat "$WORK/again.log"; fail 'install.sh new, again'; }
has "$(cat "$WORK/again.log")" 'already set, kept'
has "$(tail -n 1 "$FAKE_GH/ruleset.log")" 'PUT repos/ana/demo/rulesets/7'
# Without rulesets (GitHub Free, private) or with a token that is not one, it says so and goes on.
rm "$FAKE_GH/ruleset.json"
out=$(FAKE_GH_FREE=1 CLAUDE_CODE_OAUTH_TOKEN=not-a-token demo/scripts/setup-github.sh --replace-token </dev/null)
has "$out" 'GitHub Free has no rules for private repositories'
has "$out" 'Secret CLAUDE_CODE_OAUTH_TOKEN: not saved.'
[ "$(cat "$FAKE_GH/token")" = sk-ant-oat01-test-token ] || fail 'a token that is not one replaced the secret'
mkdir -p "$WORK/other" && echo x >"$WORK/other/notes.txt"
must_fail 'a folder that is not a project of the kit' 'install.sh existing' "$KIT/install.sh" new "$WORK/other" </dev/null
has "$(cd demo && AGENT_KIT_NO_PULL=1 "$KIT/install.sh" update </dev/null)" 'the newest'
echo 'ok'

step 'One line, curl ... | sh: the kit in ~/.agent-kit, the command agent-kit, then the project'
# Piped to sh (dash on Ubuntu), the script has no file: it fetches the kit
# (here, this repository's last commit) and runs that copy with bash.
mkdir -p "$WORK/piped" && cd "$WORK/piped"
export AGENT_KIT_URL="$KIT" AGENT_KIT_HOME="$WORK/kit-home" AGENT_KIT_BIN="$WORK/kit-bin"
sh -s -- new tool --no-github --no-user --summary 'a tool from one line' <"$KIT/install.sh" >"$WORK/piped.log" 2>&1 \
    || { cat "$WORK/piped.log"; fail 'install.sh piped to sh'; }
[ -f "$AGENT_KIT_HOME/install.sh" ] && [ -x "$AGENT_KIT_BIN/agent-kit" ] || fail 'the kit or the command agent-kit'
[ -f tool/AGENTS.md ] && [ ! -e tool/init-project.sh ] || fail 'the project made from one line'
has "$("$AGENT_KIT_BIN/agent-kit" --help)" 'install.sh new NAME'
# Again, with nothing to do and no terminal: the kit is updated and it says what to type.
has "$(sh <"$KIT/install.sh" 2>&1)" 'Run: agent-kit new my-project'
must_fail 'Windows without WSL' 'run this in WSL' env AGENT_KIT_UNAME=MINGW64_NT-10.0 sh -s <"$KIT/install.sh"
unset AGENT_KIT_URL AGENT_KIT_HOME AGENT_KIT_BIN
echo 'ok'

step 'An agent installs in the folder it was opened in (INSTALL-AGENT.md)'
# What Claude Code leaves in a new folder, and an empty repository on another branch.
mkdir -p "$WORK/here/.claude" && cd "$WORK/here"
git init -q -b master && echo '{}' >.claude/settings.local.json
"$KIT/install.sh" new . --no-github --no-user --summary 'a tool made here' </dev/null >"$WORK/here.log" 2>&1 \
    || { cat "$WORK/here.log"; fail 'install.sh new . in a folder with only what an agent leaves'; }
[ "$(git branch --show-current)" = main ] && [ "$(git log --format=%s)" != '' ] || fail 'the first commit is not on main'
[ "$(cat .claude/settings.local.json)" = '{}' ] && [ -f .claude/settings.json ] || fail 'the settings of the folder'
has "$(cat README.md)" '# here'
mkdir -p "$WORK/notes" && echo x >"$WORK/notes/a.txt"
must_fail 'a folder with files, taken for a new project' 'install.sh existing' "$KIT/install.sh" new "$WORK/notes" </dev/null
# Every option the procedure gives the agent exists.
for option in $(grep -oE -- '--[a-z][a-z-]+' "$KIT/INSTALL-AGENT.md" | sort -u); do
    case "$option" in --summary|--name|--owner|--owner-lang|--dashboard-lang|--repo-lang|--timezone|--license|--tools|--copy) ;;
        *) grep -qF -- "$option)" "$KIT/install.sh" "$KIT/user-level/install-user.sh" \
               || fail "INSTALL-AGENT.md names $option, which no script has" ;;
    esac
done
echo 'ok'

step 'The installer adds the kit to a project under way without overwriting it'
mkdir -p "$WORK/app/.claude" "$WORK/app/.github/workflows" "$WORK/app/docs"
cd "$WORK/app"
git init -q -b main && git remote add origin https://github.com/ana/app.git
git init -q --bare "$FAKE_GH/remote/ana/app.git"
echo '# Our rules' >AGENTS.md
echo 'Be brief.' >CLAUDE.md
echo '{"permissions": {"allow": ["Bash(npm test)"]}}' >.claude/settings.json
printf 'node_modules/\n.env\n' >.gitignore
echo 'name: CI' >.github/workflows/checks.yml
echo 'Hello {{OWNER}}, from our own templates.' >docs/README.md
echo '# App' >README.md
git add -A && git commit -qm 'The app'
"$KIT/install.sh" existing --no-user </dev/null >"$WORK/existing.log" 2>&1 || { cat "$WORK/existing.log"; fail 'install.sh existing'; }
[ "$(git branch --show-current)" = agent-kit ] || fail 'the kit is not on a branch of its own'
has "$(cat AGENTS.md)" '# Our rules'
has "$(cat AGENTS.md)" '<!-- agent-project-kit: project rules, begin -->'
has "$(cat CLAUDE.md)" 'Be brief.'
has "$(cat CLAUDE.md)" '@AGENTS.md'
has "$(cat .claude/settings.json)" 'Bash(npm test)'
has "$(cat .claude/settings.json)" 'status.py'
has "$(cat .gitignore)" 'node_modules/'
has "$(cat .gitignore)" '.claude/settings.local.json'
[ "$(cat .github/workflows/checks.yml)" = 'name: CI' ] && [ -f .github/workflows/kit-checks.yml ] || fail 'the workflow of the project'
[ "$(cat docs/README.md)" = 'Hello {{OWNER}}, from our own templates.' ] || fail 'a file of the project was changed'
[ "$(cat README.md)" = '# App' ] && [ -f docs/kit.md ] && [ -x scripts/setup-github.sh ] || fail 'the files of the kit'
has "$(cat docs/dashboard/config.toml)" 'repo = "ana/app"'
has "$(cat "$WORK/existing.log")" 'Kept yours'
has "$(python3 scripts/status.py)" 'STATE: NOT STARTED'
has "$(tail -n 1 "$FAKE_GH/ruleset.log")" 'POST repos/ana/app/rulesets'
has "$(cat "$FAKE_GH/ruleset.json")" 'Backlog, dashboard, pages, records and licences'   # found in kit-checks.yml
"$KIT/install.sh" existing --no-user </dev/null >"$WORK/existing2.log" 2>&1 || fail 'install.sh existing, again'
has "$(cat "$WORK/existing2.log")" 'The kit is already in'
[ "$(grep -c 'project rules, begin' AGENTS.md)" = 1 ] || fail 'the rules were added twice'
echo 'ok'

printf '\nThe kit works.\n'
