#!/usr/bin/env bash
# Installs the working rules and the skills of the kit for your user, so
# that every project gets them, even one not made from the template, and
# writes your defaults for new projects, so that an agent starting a
# project does not ask what it could already know.
#
# Usage: user-level/install-user.sh [--tools all|claude,codex,pi] [--dry-run]
#            [--owner NAME] [--owner-lang LANGUAGE] [--dashboard-lang en|pt-BR]
#            [--repo-lang LANGUAGE] [--timezone ZONE] [--license SPDX]
#            [--github ACCOUNT] [--replace-skills]
#
# It never overwrites a file of yours: the rules are appended to your
# global instructions file between two marker lines (and replaced there on
# a second run), a skill folder that already exists is left alone, and the
# defaults are written once, between their own marker lines, and then left
# for you to edit. A default not given is asked for at a terminal, and
# otherwise written as "ask me". After the kit changes, --replace-skills
# replaces the skills that carry the kit's names with their new version.

set -euo pipefail
KIT=$(cd "$(dirname "$0")/.." && pwd)
RULES="$KIT/user-level/AGENTS.global.md"
DEFAULTS="$KIT/user-level/owner-defaults.md"
SKILLS="$KIT/project-template/.claude/skills"
TOOLS=all DRY=0 REPLACE=0
OWNER= OWNER_LANG= DASH_LANG= REPO_LANG= TZ_= LICENSE= GITHUB=
while [ $# -gt 0 ]; do
    case "$1" in
        --tools) TOOLS=$2; shift 2 ;;
        --dry-run) DRY=1; shift ;;
        --owner) OWNER=$2; shift 2 ;;
        --owner-lang) OWNER_LANG=$2; shift 2 ;;
        --dashboard-lang) DASH_LANG=$2; shift 2 ;;
        --repo-lang) REPO_LANG=$2; shift 2 ;;
        --timezone) TZ_=$2; shift 2 ;;
        --license) LICENSE=$2; shift 2 ;;
        --github) GITHUB=$2; shift 2 ;;
        --replace-skills) REPLACE=1; shift ;;
        -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done
want() { [ "$TOOLS" = all ] || [[ ",$TOOLS," == *",$1,"* ]]; }
run() { if [ "$DRY" = 1 ]; then echo "would: $*"; else "$@"; fi; }

add_rules() {  # add_rules FILE
    local file=$1
    echo "rules  -> $file"
    [ "$DRY" = 1 ] && return
    mkdir -p "$(dirname "$file")"
    touch "$file"
    python3 - "$file" "$RULES" <<'PY'
import re, sys
path, rules = sys.argv[1], open(sys.argv[2], encoding='utf-8').read()
text = open(path, encoding='utf-8').read()
block = re.compile(r'<!-- agent-project-kit: working rules, begin -->.*?<!-- agent-project-kit: working rules, end -->\n?', re.S)
text = block.sub(lambda m: rules, text) if block.search(text) else (text.rstrip() + '\n\n' + rules if text.strip() else rules)
open(path, 'w', encoding='utf-8').write(text)
PY
}

ASKED=0
ask_defaults() {  # asks once for the defaults that were not given as options
    [ "$ASKED" = 0 ] || return 0
    ASKED=1
    ask() {  # ask VAR "question" default
        local current=${!1}
        if [ -z "$current" ]; then
            if [ -t 0 ] && [ "$DRY" = 0 ]; then read -r -p "$2 [$3]: " current; fi
            printf -v "$1" '%s' "${current:-$3}"
        fi
    }
    ask OWNER 'Your name, as the owner of your projects' "$(git config --global user.name 2>/dev/null || echo 'ask me')"
    ask OWNER_LANG 'Language of reports and of the dashboard' 'ask me'
    ask DASH_LANG 'Dashboard language code (en or pt-BR)' 'en'
    ask REPO_LANG 'Language of the repository (code, comments, documentation)' 'English'
    ask TZ_ 'Your time zone (for example America/Sao_Paulo)' 'ask me'
    ask LICENSE 'SPDX licence you use by default' 'ask me'
    ask GITHUB 'GitHub account for new repositories' 'ask me'
}
add_defaults() {  # add_defaults FILE
    local file=$1
    if grep -q 'agent-project-kit: owner defaults, begin' "$file" 2>/dev/null; then
        echo "defaults -> $file (kept yours)"
        return
    fi
    echo "defaults -> $file"
    [ "$DRY" = 1 ] && return
    ask_defaults
    OWNER=$OWNER OWNER_LANG=$OWNER_LANG DASH_LANG=$DASH_LANG REPO_LANG=$REPO_LANG TZ_=$TZ_ \
        LICENSE=$LICENSE GITHUB=$GITHUB python3 - "$file" "$DEFAULTS" <<'PY'
import os, sys
path, block = sys.argv[1], open(sys.argv[2], encoding='utf-8').read()
for token, var in (('OWNER_NAME', 'OWNER'), ('OWNER_LANGUAGE', 'OWNER_LANG'), ('DASHBOARD_LANG', 'DASH_LANG'),
                   ('REPO_LANGUAGE', 'REPO_LANG'), ('TIMEZONE', 'TZ_'), ('LICENSE', 'LICENSE'),
                   ('GITHUB_ACCOUNT', 'GITHUB')):
    block = block.replace(token, os.environ[var])
text = open(path, encoding='utf-8').read()
open(path, 'w', encoding='utf-8').write(text.rstrip() + '\n\n' + block if text.strip() else block)
PY
}
add_skills() {  # add_skills DIR
    echo "skills -> $1"
    run mkdir -p "$1"
    for s in "$SKILLS"/*/; do
        local name; name=$(basename "$s")
        if [ -e "$1/$name" ] && [ "$REPLACE" = 1 ]; then
            echo "  replaced $name"; run rm -rf "$1/$name"; run cp -R "$s" "$1/$name"
        elif [ -e "$1/$name" ]; then
            echo "  kept your existing $name"
        else
            run cp -R "$s" "$1/$name"
        fi
    done
}
install_for() {  # install_for INSTRUCTIONS_FILE SKILLS_DIR
    add_rules "$1"
    add_defaults "$1"
    add_skills "$2"
}

if want claude; then install_for "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills"; fi
if want codex; then install_for "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" "${CODEX_HOME:-$HOME/.codex}/skills"; fi
if want pi; then install_for "$HOME/.pi/agent/AGENTS.md" "$HOME/.pi/agent/skills"; fi
echo 'Done. Restart the agents so they read the new files.'
[ "$REPLACE" = 1 ] || echo 'Skills you already had were kept; run again with --replace-skills to take the new version of the kit'"'"'s.'
