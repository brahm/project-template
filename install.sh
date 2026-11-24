#!/usr/bin/env bash
# Installs the agent project kit, in one command, on your computer.
#
#   install.sh new NAME [options]      a new project: the folder NAME (or .,
#                                      an empty current folder), filled from
#                                      the template, a private GitHub
#                                      repository, the automatic review on
#   install.sh existing [DIR] [opts]   the kit in a project under way (DIR, or
#                                      the current folder), without
#                                      overwriting any file of yours
#   install.sh update [DIR]            the newest kit for your user, and what
#                                      to do in the project DIR
#   install.sh github [DIR]            only the GitHub part: the secret of the
#                                      review and the rules of main
#   install.sh user [options]          only the rules and skills for your user
#                                      (user-level/install-user.sh)
#
# Options of new and existing:
#   --public              make the new repository public (default: private)
#   --github-owner NAME   create the repository under this account or
#                         organisation (default: the one gh is signed in as)
#   --no-github           do nothing on GitHub
#   --no-rules            save the secret, but leave the rules of main alone
#   --user / --no-user    install (or not) the rules and skills for your user
#                         too; without either, asked when they are missing
#   --name, --summary, --owner, --repo-lang, --owner-lang, --dashboard-lang,
#   --timezone, --license, --dashboard-url, --tools, --copy
#                         passed to init-project.sh; a value not given comes
#                         from your defaults (install-user.sh), or is asked
#
# Every command can be run again: what is done is kept, what is missing is
# done. Needs bash, git, Python 3.11 or later, and for GitHub the CLI gh.
#
# In one line, on Linux, macOS or Windows (in WSL), with no copy of the kit:
#
#   curl -fsSL https://raw.githubusercontent.com/brahm/project-template/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- new my-project
#
# Run that way, it keeps the kit in ~/.agent-kit (AGENT_KIT_HOME), updating
# it when it is there, adds the command agent-kit to ~/.local/bin, and then
# does what the arguments say; with none, it asks what to do here.

# ---------------------------------------------------------------------------
# The part up to the next line of dashes is POSIX sh: piped to sh, this
# script has no file and maybe no bash, so it fetches the kit and runs the
# kit's copy with bash, giving it the terminal for its questions.
here=
case $0 in
    */install.sh|install.sh) [ -f "$0" ] && here=$(cd "$(dirname "$0")" && pwd) ;;
esac
if [ -n "$here" ] && [ -f "$here/project-template/docs/kit.md" ]; then
    [ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
else
    set -eu
    say() { printf '%s\n' "$*"; }
    die() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
    case ${AGENT_KIT_UNAME:-$(uname -s)} in
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                case $PWD in /mnt/[a-z]/*) say 'Note: a project under /mnt/c is slower in WSL; one in your WSL home (cd ~) is faster.' ;; esac
            fi ;;
        Darwin) ;;
        MINGW*|MSYS*|CYGWIN*)
            die 'on Windows, run this in WSL. In PowerShell, once: wsl --install; then open "Ubuntu" from the Start menu and run the same command there.' ;;
        *) say "Note: $(uname -s) was not tested; going on." ;;
    esac
    missing=
    for tool in git bash python3; do command -v "$tool" >/dev/null 2>&1 || missing="$missing $tool"; done
    if [ -n "$missing" ]; then
        if [ "$(uname -s)" = Darwin ]; then hint='brew install git bash python (https://brew.sh), or: xcode-select --install'
        else hint="sudo apt install git bash python3 (or your system's package manager)"; fi
        die "missing:$missing. Install it ($hint) and run the same command again."
    fi
    kit=${AGENT_KIT_HOME:-$HOME/.agent-kit}
    url=${AGENT_KIT_URL:-https://github.com/brahm/project-template}
    if [ -d "$kit/.git" ]; then
        git -C "$kit" pull -q --ff-only || say "Could not update $kit with git pull; using it as it is."
    elif [ -e "$kit" ]; then
        die "$kit exists and is not a copy of the kit; move it, or set AGENT_KIT_HOME to another folder"
    else
        say "Fetching the kit into $kit ..."
        git clone -q --depth 1 "$url" "$kit" || die "could not fetch the kit from $url"
    fi
    # The command agent-kit, for next time: agent-kit new NAME, agent-kit update...
    bin=${AGENT_KIT_BIN:-$HOME/.local/bin}
    mkdir -p "$bin"
    printf '#!/bin/sh\nexec bash "%s/install.sh" "$@"\n' "$kit" >"$bin/agent-kit"
    chmod +x "$bin/agent-kit"
    case ":$PATH:" in
        *":$bin:"*) ;;
        *) say "Added the command agent-kit to $bin, which is not in your PATH: add it (for example in ~/.profile) to type agent-kit next time." ;;
    esac
    # The questions need the terminal: stdin is the script itself, or nothing.
    # (In a subshell: sh leaves at once when the redirection of a builtin fails.)
    if (true </dev/tty) 2>/dev/null; then has_tty=1; else has_tty=; fi
    if [ $# -eq 0 ]; then
        if [ -z "$has_tty" ]; then
            say "The kit is in $kit. Run: agent-kit new my-project, or agent-kit existing, in the project's folder."
            exit 0
        fi
        if [ -f docs/kit.md ]; then choice=3
        elif git rev-parse -q --verify HEAD >/dev/null 2>&1 || [ -n "$(ls -A 2>/dev/null | grep -vxE '\.git|\.claude|\.DS_Store')" ]; then choice=2
        else choice=1; fi
        say '' "The agent project kit is in $kit. What now, in $PWD?" \
            '  1) Start a new project' \
            '  2) Add the kit to the project in this folder (nothing of yours is overwritten)' \
            '  3) Update the kit, and this project' \
            '  4) Nothing more for now (next time, type agent-kit)'
        printf 'Choice [%s]: ' "$choice"
        read -r answer </dev/tty || answer=
        case ${answer:-$choice} in
            1) if [ "$choice" = 1 ]; then set -- new .
               else
                   printf 'Name of the new project (a folder made here): '
                   read -r name </dev/tty || name=
                   [ -n "$name" ] || die 'no name given'
                   set -- new "$name"
               fi ;;
            2) set -- existing . ;;
            3) if [ -f docs/kit.md ]; then set -- update .; else set -- update; fi ;;
            *) exit 0 ;;
        esac
    fi
    if [ -n "$has_tty" ]; then exec bash "$kit/install.sh" "$@" </dev/tty; fi
    exec bash "$kit/install.sh" "$@"
fi
# ---------------------------------------------------------------------------

set -euo pipefail

say() { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
die() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
tty() { [ -t 0 ]; }
confirm() {  # confirm "question" default(y|n): true for yes; the default without a terminal
    local answer
    if tty; then read -r -p "$1 [$([ "$2" = y ] && echo Y/n || echo y/N)]: " answer || answer=; fi
    answer=${answer:-$2}
    [[ "$answer" =~ ^[yYsS] ]]
}

KIT=$here
TEMPLATE=$KIT/project-template
KIT_VERSION=$(sed -nE 's/^\| Kit version \| ([^ ]+) \|$/\1/p' "$TEMPLATE/docs/kit.md")

usage() { sed -n '2,42p' "$KIT/install.sh"; }
[ $# -gt 0 ] || { usage; exit 2; }
COMMAND=$1; shift
case "$COMMAND" in
    -h|--help|help) usage; exit 0 ;;
    user) exec "$KIT/user-level/install-user.sh" "$@" ;;
esac

TARGET= PUBLIC=0 GITHUB=1 RULES=1 USER_STEP=ask GH_OWNER=
INIT_ARGS=()
GIVEN=' '    # the options of init-project.sh given here (no associative array: macOS has bash 3.2)
while [ $# -gt 0 ]; do
    case "$1" in
        --public) PUBLIC=1; shift ;;
        --github-owner) GH_OWNER=$2; shift 2 ;;
        --no-github) GITHUB=0; shift ;;
        --no-rules) RULES=0; shift ;;
        --user) USER_STEP=yes; shift ;;
        --no-user) USER_STEP=no; shift ;;
        --copy) INIT_ARGS+=(--copy); shift ;;
        --name|--summary|--owner|--repo-lang|--owner-lang|--dashboard-lang|--timezone|--license|--dashboard-url|--tools)
            [ $# -ge 2 ] || die "$1 needs a value"
            INIT_ARGS+=("$1" "$2"); GIVEN="$GIVEN$1 "; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        -*) die "unknown option: $1 (install.sh --help)" ;;
        *) [ -z "$TARGET" ] || die "one folder only, not \"$TARGET\" and \"$1\""; TARGET=$1; shift ;;
    esac
done

need_tools() {
    command -v git >/dev/null || die 'git is not installed'
    command -v python3 >/dev/null || die 'Python 3 is not installed (3.11 or later)'
    python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' || die 'Python 3.11 or later is needed'
}

# GitHub: the CLI, signed in, with the scope that lets git push workflows.
need_gh() {
    command -v gh >/dev/null || die 'the GitHub CLI is not installed: https://cli.github.com, or run with --no-github'
    if ! gh auth status >/dev/null 2>&1; then
        tty || die 'the GitHub CLI is not signed in: run gh auth login'
        say 'The GitHub CLI is not signed in. Signing in now:'
        gh auth login -h github.com -s workflow
    fi
    # A push that adds .github/workflows needs the "workflow" scope.
    local status; status=$(gh auth status -h github.com 2>&1 || true)
    if grep -q 'Token scopes' <<<"$status" && ! grep -q "'workflow'" <<<"$status"; then
        tty || die 'gh needs the "workflow" scope to push the workflows: run gh auth refresh -s workflow'
        say 'gh needs the "workflow" scope to push the workflows of the kit. Adding it:'
        gh auth refresh -h github.com -s workflow
    fi
}

# Your defaults for new projects, written by install-user.sh, fill the
# values of init-project.sh that were not given.
use_defaults() {
    local file=$HOME/.claude/CLAUDE.md line value
    [ -f "$file" ] || file=${CODEX_HOME:-$HOME/.codex}/AGENTS.md
    [ -f "$file" ] || return 0
    while IFS=$'\t' read -r line value; do
        if ! given "$line" && [ -n "$value" ]; then INIT_ARGS+=("$line" "$value"); GIVEN="$GIVEN$line "; fi
    done < <(python3 - "$file" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
m = re.search(r'agent-project-kit: owner defaults, begin -->(.*?)<!--', text, re.S)
if not m:
    sys.exit()
keys = {'Owner': '--owner', 'Language of the repository': '--repo-lang', 'Time zone': '--timezone',
        'Licence': '--license'}
for line in m.group(1).splitlines():
    k, _, v = line.lstrip('- ').partition(': ')
    v = v.strip()
    if v and 'ask me' not in v:
        if k == 'Language of reports and of the dashboard':
            lang = re.match(r'(.*?) \(dashboard code (\S+)\)$', v)
            if lang:
                print(f'--owner-lang\t{lang.group(1)}\n--dashboard-lang\t{lang.group(2)}')
        elif k.startswith('Language of the repository'):
            print(f'--repo-lang\t{v}')
        elif k in keys:
            print(f'{keys[k]}\t{v}')
PY
)
}

given() { [[ "$GIVEN" == *" $1 "* ]]; }
init() {  # init DIR: runs its init-project.sh with the values gathered (an empty array is unbound in bash 3.2)
    (cd "$1" && KIT_INSTALLER=1 ./init-project.sh ${INIT_ARGS[@]+"${INIT_ARGS[@]}"})
}
gh_account() { if [ -n "$GH_OWNER" ]; then echo "$GH_OWNER"; else gh api user --jq .login; fi; }
push() {  # push DIR BRANCH: through gh's credentials, without changing your git settings
    git -C "$1" -c credential.helper= -c 'credential.helper=!gh auth git-credential' push -u origin "$2"
}
user_step() {
    local marker='agent-project-kit: working rules, begin'
    case "$USER_STEP" in
        no) return ;;
        ask) if grep -qs "$marker" "$HOME/.claude/CLAUDE.md" "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"; then return; fi
             confirm 'Also install the rules and skills of the kit for your user (all your projects)?' n || return 0 ;;
    esac
    step 'The rules and skills for your user'
    "$KIT/user-level/install-user.sh"
}
github_step() {  # github_step DIR REPO
    step "GitHub: the automatic review of $2"
    local args=(--repo "$2")
    [ "$RULES" = 1 ] || args+=(--no-rules)
    "$TEMPLATE/scripts/setup-github.sh" --dir "$1" "${args[@]}"
}
origin_repo() {  # the owner/name of the GitHub remote origin of DIR, or nothing
    git -C "$1" config --get remote.origin.url 2>/dev/null \
        | sed -nE 's#^(https?://|git@|ssh://git@)github\.com[:/]([^/]+/[^/]+)$#\2#p' | sed 's/\.git$//' || true
}

empty_folder() {  # empty_folder DIR: nothing in it but what an agent or the system leaves in a new folder
    local dir=$1
    [ -z "$(ls -A "$dir" | grep -vxE '\.git|\.claude|\.DS_Store' || true)" ] || return 1
    # A git repository without commits, and Claude Code's own settings of the folder.
    if [ -e "$dir/.git" ] && git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then return 1; fi
    if [ -d "$dir/.claude" ] && [ -n "$(ls -A "$dir/.claude" | grep -vx settings.local.json || true)" ]; then return 1; fi
    return 0
}

cmd_new() {
    [ -n "$TARGET" ] || die 'name the folder of the new project: install.sh new my-project'
    need_tools
    local dir name repo=
    if [ -d "$TARGET" ]; then           # "." when an agent runs it in the folder it was opened in
        dir=$(cd "$TARGET" && pwd)
    else
        dir=$(mkdir -p "$(dirname "$TARGET")" && cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")
    fi
    name=$(basename "$dir")
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] \
        || die "\"$name\" cannot be the name of a GitHub repository: use letters, digits, dots, hyphens or underscores"
    if [ -d "$dir" ] && [ ! -f "$dir/docs/kit.md" ] && ! empty_folder "$dir"; then
        die "$dir already has files; to add the kit to them: install.sh existing $TARGET"
    fi
    if [ "$GITHUB" = 1 ]; then
        need_gh
        repo=$(gh_account)/$name
    fi

    if [ ! -f "$dir/docs/kit.md" ]; then
        step "The project $name, from the template (kit $KIT_VERSION)"
        mkdir -p "$dir"
        cp -R "$TEMPLATE/." "$dir/"
        git -C "$dir" init -q -b main
        git -C "$dir" symbolic-ref HEAD refs/heads/main   # a folder that was already an empty repository
    fi
    if [ -f "$dir/init-project.sh" ]; then
        use_defaults
        given --name || INIT_ARGS+=(--name "$name")
        [ -z "$repo" ] || INIT_ARGS+=(--repo "$repo")
        init "$dir"
    fi
    if ! git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then
        git -C "$dir" add -A
        git -C "$dir" commit -q -m "Start from the agent project kit $KIT_VERSION" \
            || die 'git could not commit: set your name and e-mail (git config --global user.name / user.email)'
        say "First commit made in $dir."
    fi

    if [ "$GITHUB" = 1 ]; then
        step "GitHub: the repository $repo"
        if gh repo view "$repo" >/dev/null 2>&1; then
            say "$repo already exists: using it."
        else
            gh repo create "$repo" "$([ "$PUBLIC" = 1 ] && echo --public || echo --private)" >/dev/null
            say "Created $repo ($([ "$PUBLIC" = 1 ] && echo public || echo private))."
        fi
        if [ -z "$(origin_repo "$dir")" ]; then
            local url="https://github.com/$repo.git"
            [ "$(gh config get git_protocol -h github.com 2>/dev/null)" != ssh ] || url="git@github.com:$repo.git"
            git -C "$dir" remote add origin "$url"
        fi
        push "$dir" main || die "the push to $repo failed (see above); fix it and run the same command again"
        say "Pushed main to $repo."
        github_step "$dir" "$repo"
    fi
    user_step
    cat <<MSG

The project is ready in $dir.
Next: open your coding agent there (cd "$dir", then claude, codex, ...)
and say, in your own words, what you want to build. It plans the project
by itself and reports what it assumed.
MSG
}

cmd_existing() {
    local dir=${TARGET:-.}
    [ -d "$dir" ] || die "$dir is not a folder"
    dir=$(cd "$dir" && pwd)
    need_tools
    git -C "$dir" rev-parse --show-toplevel >/dev/null 2>&1 \
        || die "$dir is not a git repository; run git init there first, or start a new project with install.sh new"
    [ "$(git -C "$dir" rev-parse --show-toplevel)" = "$dir" ] || die "run it at the root of the repository: $(git -C "$dir" rev-parse --show-toplevel)"
    local repo
    repo=$(origin_repo "$dir")
    if [ "$GITHUB" = 1 ]; then
        if [ -z "$repo" ]; then
            say 'No GitHub remote "origin" here: the GitHub part is skipped (run install.sh github later).'
            GITHUB=0
        else
            need_gh
        fi
    fi

    if [ -f "$dir/docs/kit.md" ]; then
        say "The kit is already in $dir (docs/kit.md). To take a newer version: install.sh update $dir"
    else
        # A branch of its own, so that the kit arrives by pull request.
        if [ -z "$(git -C "$dir" status --porcelain)" ] && git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then
            if git -C "$dir" rev-parse -q --verify refs/heads/agent-kit >/dev/null; then
                git -C "$dir" switch -q agent-kit
            else
                git -C "$dir" switch -q -c agent-kit
            fi
            say 'On the branch agent-kit.'
        else
            say 'The working tree has changes (or no commit yet): the kit is added on the current branch.'
        fi

        step "The kit $KIT_VERSION, filled in a copy of the template"
        local work; work=$(mktemp -d)
        cp -R "$TEMPLATE/." "$work/"
        use_defaults
        given --name || INIT_ARGS+=(--name "$(basename "$dir")")
        [ -z "$repo" ] || INIT_ARGS+=(--repo "$repo")
        init "$work" || { rm -rf "$work"; die 'init-project.sh failed'; }

        step "Into $dir, without overwriting anything"
        python3 - "$work" "$dir" <<'PY'
import json, os, pathlib, shutil, sys

src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
added, merged, renamed, kept = [], [], [], []
BEGIN, END = '<!-- agent-project-kit: {}, begin -->', '<!-- agent-project-kit: {}, end -->'


def block(path, name, body):
    """Puts BODY between marker lines at the end of PATH, or in place of an earlier copy."""
    text = path.read_text(encoding='utf-8')
    begin, end = BEGIN.format(name), END.format(name)
    new = f'{begin}\n{body.rstrip()}\n{end}\n'
    if begin in text and end in text:
        head, rest = text.split(begin, 1)
        text = head + new + rest.split(end, 1)[1].lstrip('\n')
    else:
        text = text.rstrip() + '\n\n' + new if text.strip() else new
    path.write_text(text, encoding='utf-8')


def lines(path, new_lines, comment):
    """Adds the lines that PATH lacks, under COMMENT."""
    text = path.read_text(encoding='utf-8')
    have = {l.strip() for l in text.splitlines()}
    missing = [l for l in new_lines if l.strip() and not l.startswith('#') and l.strip() not in have]
    if missing:
        path.write_text(text.rstrip('\n') + f'\n\n{comment}\n' + '\n'.join(missing) + '\n', encoding='utf-8')
    return bool(missing)


def settings(path, kit):
    """Merges the permissions and hooks of the kit's .claude/settings.json into the project's."""
    mine = json.loads(path.read_text(encoding='utf-8') or '{}')
    allow = mine.setdefault('permissions', {}).setdefault('allow', [])
    allow += [p for p in kit['permissions']['allow'] if p not in allow]
    for event, entries in kit.get('hooks', {}).items():
        have = mine.setdefault('hooks', {}).setdefault(event, [])
        commands = {h.get('command') for e in have for h in e.get('hooks', [])}
        have += [e for e in entries if not any(h['command'] in commands for h in e['hooks'])]
    path.write_text(json.dumps(mine, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def copy(s, d):
    d.parent.mkdir(parents=True, exist_ok=True)
    if s.is_symlink():
        os.symlink(os.readlink(s), d)
    elif s.is_dir():
        shutil.copytree(s, d, symlinks=True)
    else:
        shutil.copy2(s, d)


def same(a, b):
    return a.is_file() and b.is_file() and not a.is_symlink() and not b.is_symlink() \
        and a.read_bytes() == b.read_bytes()


def walk(s_dir):
    """The kit's files, with a skill folder or a linked folder taken whole."""
    for s in sorted(s_dir.iterdir()):
        rel = s.relative_to(src)
        if s.is_symlink() or rel.parent.as_posix() == '.claude/skills':
            yield s
        elif s.is_dir():
            yield from walk(s)
        else:
            yield s


for s in walk(src):
    rel = s.relative_to(src)
    d = dst / rel
    name = rel.as_posix()
    if not os.path.lexists(d):
        copy(s, d)
        added.append(name)
    elif same(s, d):
        pass
    elif name == 'AGENTS.md':
        block(d, 'project rules', s.read_text(encoding='utf-8'))
        merged.append(name + ' (the rules of the kit added at its end)')
    elif name == 'CLAUDE.md':
        if '@AGENTS.md' not in d.read_text(encoding='utf-8'):
            block(d, 'pointer', s.read_text(encoding='utf-8').replace('# Claude\n', '', 1))
            merged.append(name + ' (now imports AGENTS.md)')
    elif name == '.claude/settings.json':
        try:
            settings(d, json.loads(s.read_text(encoding='utf-8')))
            merged.append(name + ' (permissions and hooks added)')
        except (ValueError, AttributeError):
            kept.append(name + ' (not plain JSON: add the hooks of the kit by hand)')
    elif name in ('.gitignore', '.github/CODEOWNERS'):
        if lines(d, s.read_text(encoding='utf-8').splitlines(), '# Added by the agent project kit'):
            merged.append(name + ' (lines added)')
    elif name.startswith('.github/workflows/'):
        alt = d.with_name('kit-' + d.name)
        if not os.path.lexists(alt):
            copy(s, alt)
            renamed.append(f'{name} -> {alt.relative_to(dst).as_posix()} (yours has the same name)')
        elif not same(s, alt):
            kept.append(alt.relative_to(dst).as_posix())
    else:
        kept.append(name)

report = [('Added', added), ('Merged', merged), ('Added under another name', renamed),
          ('Kept yours (the kit has its own version: the agent merges them when it adopts the kit)', kept)]
for title, items in report:
    if items:
        print(f'{title}:')
        print(''.join(f'  {i}\n' for i in items), end='')
PY
        rm -rf "$work"
    fi

    if [ "$GITHUB" = 1 ]; then
        if [ "$RULES" = 1 ] && ! confirm 'Protect main on GitHub? From then on, main changes only through pull requests whose checks pass.' y; then
            RULES=0
        fi
        github_step "$dir" "$repo"
    fi
    user_step
    cat <<MSG

The kit is in $dir, not yet committed: see git status.
Next: open your coding agent there and say "adopt the kit in this project"
(or "adote o kit neste projeto"). It reads the code, writes the goals,
the plan and the decisions from what exists, merges the files listed
above as kept, makes the checks pass, and opens a pull request.
MSG
}

cmd_update() {
    need_tools
    # AGENT_KIT_NO_PULL=1 keeps the copy as it is (the tests).
    if [ -z "${AGENT_KIT_NO_PULL:-}" ] && git -C "$KIT" rev-parse -q --verify HEAD >/dev/null 2>&1; then
        step 'The kit'
        if git -C "$KIT" pull -q --ff-only; then
            KIT_VERSION=$(sed -nE 's/^\| Kit version \| ([^ ]+) \|$/\1/p' "$TEMPLATE/docs/kit.md")
            say "The kit in $KIT is at version $KIT_VERSION."
        else
            say "Could not update $KIT with git pull; it stays at $KIT_VERSION."
        fi
    fi
    if grep -qs 'agent-project-kit: working rules, begin' "$HOME/.claude/CLAUDE.md" \
        "${CODEX_HOME:-$HOME/.codex}/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"; then
        step 'The rules and skills for your user'
        "$KIT/user-level/install-user.sh" --replace-skills
    fi
    local dir=${TARGET:-.}
    if [ -f "$dir/docs/kit.md" ]; then
        local have
        have=$(sed -nE 's/^\| Kit version \| ([^ ]+) \|$/\1/p' "$dir/docs/kit.md")
        step "The project in $(cd "$dir" && pwd)"
        if [ "$have" = "$KIT_VERSION" ]; then
            say "It has the kit $have, the newest."
        else
            say "It has the kit $have; the newest is $KIT_VERSION."
            say 'Open your coding agent there and say "update the kit" (or "atualize o kit"): it reads'
            say 'what changed in HISTORY.md and brings it in without losing what was fitted to the project'
            say '(the update-from-template skill).'
        fi
    elif [ -n "$TARGET" ]; then
        die "$TARGET has no docs/kit.md: it is not a project of the kit (install.sh existing $TARGET)"
    fi
}

cmd_github() {
    local dir=${TARGET:-.} repo
    dir=$(cd "$dir" && pwd)
    need_gh
    repo=$(origin_repo "$dir")
    [ -n "$repo" ] || die "$dir has no GitHub remote origin"
    github_step "$dir" "$repo"
}

case "$COMMAND" in
    new) cmd_new ;;
    existing) cmd_existing ;;
    update) cmd_update ;;
    github) cmd_github ;;
    *) die "unknown command: $COMMAND (install.sh --help)" ;;
esac
