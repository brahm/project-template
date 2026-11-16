#!/usr/bin/env bash
# Fills the placeholders of this template and sets up the files each coding
# agent reads. Run it once, at the root of the new project, then delete it
# (it deletes itself and TEMPLATE.md unless --keep is given). A coding
# agent runs it by itself when it finds it here (the start-project skill),
# giving every value as an option.
#
# Usage:
#   ./init-project.sh --name "Acme" --summary "a tool that does X" \
#       --owner "Ana" [--repo owner/acme] [--repo-lang English] \
#       [--owner-lang "Brazilian Portuguese"] [--dashboard-lang pt-BR] \
#       [--timezone America/Sao_Paulo] [--license MIT] \
#       [--dashboard-url URL] [--tools all|claude,codex,pi,gemini,copilot,cursor] \
#       [--copy] [--keep]
#
# Values not given are asked for at a terminal, and otherwise take their
# default: the name of the folder, the git user, the `origin` remote.
# --copy copies the skills for each agent instead of linking them (use it
# on Windows). Needs bash, sed and python3.

set -euo pipefail
cd "$(dirname "$0")"

NAME= SUMMARY= OWNER= REPO= REPO_LANG= OWNER_LANG= DASH_LANG= TZ_= LICENSE= DASH_URL= TOOLS=all COPY=0 KEEP=0
while [ $# -gt 0 ]; do
    case "$1" in
        --name) NAME=$2; shift 2 ;;
        --summary) SUMMARY=$2; shift 2 ;;
        --owner) OWNER=$2; shift 2 ;;
        --repo) REPO=$2; shift 2 ;;
        --repo-lang) REPO_LANG=$2; shift 2 ;;
        --owner-lang) OWNER_LANG=$2; shift 2 ;;
        --dashboard-lang) DASH_LANG=$2; shift 2 ;;
        --timezone) TZ_=$2; shift 2 ;;
        --license) LICENSE=$2; shift 2 ;;
        --dashboard-url) DASH_URL=$2; shift 2 ;;
        --tools) TOOLS=$2; shift 2 ;;
        --copy) COPY=1; shift ;;
        --keep) KEEP=1; shift ;;
        -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

ask() {  # ask VAR "question" default
    local current=${!1}
    if [ -z "$current" ]; then
        if [ -t 0 ]; then read -r -p "$2 [$3]: " current; fi
        printf -v "$1" '%s' "${current:-$3}"
    fi
}
# Defaults taken from the place the script runs in, so that an agent or a
# person in a hurry has less to type.
DIR_NAME=$(basename "$PWD")
[ "$DIR_NAME" != project-template ] || DIR_NAME='My project'
GIT_USER=$(git config user.name 2>/dev/null || true)
GIT_REPO=$(git remote get-url origin 2>/dev/null \
    | sed -nE 's#^(https?://|git@|ssh://git@)github\.com[:/]([^/]+/[^/]+)$#\2#p' | sed 's/\.git$//' || true)

ask NAME 'Project name' "$DIR_NAME"
ask SUMMARY 'One-line summary (completes "NAME is ...")' 'a new project'
ask OWNER 'Owner (who decides and approves)' "${GIT_USER:-the owner}"
ask REPO 'GitHub repository owner/name (empty for none)' "$GIT_REPO"
ask REPO_LANG 'Language of the repository' 'English'
ask OWNER_LANG 'Language of reports and dashboard' "$REPO_LANG"
ask DASH_LANG 'Dashboard language code (en or pt-BR)' 'en'
ask TZ_ 'Time zone of the owner' 'UTC'
ask LICENSE 'SPDX licence of the project' 'MIT'
ask DASH_URL 'Address of a hosted copy of the dashboard (empty for none)' ''

TODAY=$(date +%F)
YEAR=$(date +%Y)
[ -n "$DASH_URL" ] || DASH_URL='none yet (set it here when the owner creates one)'

# Replace the placeholders in every text file of the template.
export NAME SUMMARY OWNER REPO REPO_LANG OWNER_LANG DASH_LANG TZ_ LICENSE DASH_URL TODAY YEAR
python3 - <<'PY'
import os, pathlib
subs = {'{{PROJECT_NAME}}': 'NAME', '{{PROJECT_SUMMARY}}': 'SUMMARY', '{{OWNER}}': 'OWNER',
        '{{REPO}}': 'REPO', '{{REPO_LANGUAGE}}': 'REPO_LANG', '{{OWNER_LANGUAGE}}': 'OWNER_LANG',
        '{{DASHBOARD_LANG}}': 'DASH_LANG', '{{TIMEZONE}}': 'TZ_', '{{LICENSE}}': 'LICENSE',
        '{{DASHBOARD_URL}}': 'DASH_URL', '{{TODAY}}': 'TODAY', '{{YEAR}}': 'YEAR'}
skip = {'init-project.sh', 'TEMPLATE.md'}
for path in pathlib.Path('.').rglob('*'):
    if not path.is_file() or path.is_symlink() or '.git' in path.parts or path.name in skip:
        continue
    try:
        text = path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        continue
    new = text
    for key, var in subs.items():
        new = new.replace(key, os.environ[var])
    if new != text:
        path.write_text(new, encoding='utf-8')
PY

# Give each agent the shared skills and a pointer to AGENTS.md.
want() { [ "$TOOLS" = all ] || [[ ",$TOOLS," == *",$1,"* ]]; }
link_skills() {  # link_skills DIR
    mkdir -p "$(dirname "$1")"
    rm -rf "$1"
    if [ "$COPY" = 1 ]; then
        cp -R .claude/skills "$1"
    else
        local up; up=$(dirname "$1" | sed 's|[^/][^/]*|..|g')
        ln -s "$up/.claude/skills" "$1"
    fi
}
if ! want claude; then
    rm -f CLAUDE.md
fi
want codex && link_skills .agents/skills          # Codex reads AGENTS.md itself
want pi && link_skills .pi/skills                 # Pi reads AGENTS.md itself
if want gemini; then
    mkdir -p .gemini
    printf '{\n  "context": { "fileName": ["AGENTS.md"] }\n}\n' > .gemini/settings.json
fi
if want copilot; then
    mkdir -p .github
    printf '# Copilot\n\nThe rules of this project are in [AGENTS.md](../AGENTS.md). Read it first and follow it.\n' \
        > .github/copilot-instructions.md
fi
if want cursor; then
    mkdir -p .cursor/rules
    printf -- '---\ndescription: Project rules\nalwaysApply: true\n---\n\nFollow [AGENTS.md](../../AGENTS.md), the rules of this project.\n' \
        > .cursor/rules/project.mdc
fi

python3 scripts/check-backlog.py
python3 scripts/dashboard.py --check
if command -v reuse >/dev/null; then
    reuse download --all >/dev/null 2>&1 && echo "Licence text of $LICENSE put in LICENSES/" \
        || echo "reuse could not download the licence text; run: reuse download --all"
fi

left=$(grep -rIl --exclude=init-project.sh --exclude=TEMPLATE.md --exclude-dir=.git '{{[A-Z_]*}}' . || true)
[ -z "$left" ] || { echo 'Placeholders still to fill in:'; echo "$left"; }

if [ "$KEEP" = 0 ]; then
    rm -f TEMPLATE.md "$0"
fi
cat <<MSG

Done. Next:
  1. Open your coding agent here and say what you want to build. It plans
     the project by itself (the start-project skill): goals, decisions,
     inventory, roadmap, verification, and the rules, skills and checks
     fitted to your technology. Or fill those pages of docs/ by hand, and
     then delete the "not started" section of AGENTS.md and the example
     rows (F-001 to F-007, B-001, L-001).
  2. Check that LICENSES/ has the licence text (reuse download --all).
MSG
