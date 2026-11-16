#!/usr/bin/env bash
# Installs the working rules and the skills of the kit for your user, so
# that every project gets them, even one not made from the template.
#
# Usage: user-level/install-user.sh [--tools all|claude,codex,pi] [--dry-run]
#
# It never overwrites a file of yours: the rules are appended to your
# global instructions file between two marker lines (and replaced there on
# a second run), and a skill folder that already exists is left alone.

set -euo pipefail
KIT=$(cd "$(dirname "$0")/.." && pwd)
RULES="$KIT/user-level/AGENTS.global.md"
SKILLS="$KIT/project-template/.claude/skills"
TOOLS=all DRY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --tools) TOOLS=$2; shift 2 ;;
        --dry-run) DRY=1; shift ;;
        -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
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
add_skills() {  # add_skills DIR
    echo "skills -> $1"
    run mkdir -p "$1"
    for s in "$SKILLS"/*/; do
        local name; name=$(basename "$s")
        if [ -e "$1/$name" ]; then echo "  kept your existing $name"; else run cp -R "$s" "$1/$name"; fi
    done
}

if want claude; then add_rules "$HOME/.claude/CLAUDE.md"; add_skills "$HOME/.claude/skills"; fi
if want codex; then add_rules "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"; add_skills "${CODEX_HOME:-$HOME/.codex}/skills"; fi
if want pi; then add_rules "$HOME/.pi/agent/AGENTS.md"; add_skills "$HOME/.pi/agent/skills"; fi
echo 'Done. Restart the agents so they read the new files.'
