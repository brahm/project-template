#!/usr/bin/env bash
# Turns on, for this project's GitHub repository, what the automatic review
# needs (docs/kit.md, "The automatic review"), so that nobody has to click
# through the settings:
#
#   1. the secret CLAUDE_CODE_OAUTH_TOKEN, the token of the owner's Claude
#      Pro or Max plan, made by `claude setup-token`;
#   2. a ruleset on the default branch: changes arrive by pull request, the
#      checks `Review` and those of checks.yml must pass, and a change to
#      the files of .github/CODEOWNERS waits for the owner.
#
# Usage: scripts/setup-github.sh [--repo owner/name] [--check NAME]...
#            [--replace-token] [--no-token] [--no-rules] [--dir DIR] [--dry-run]
#
# Run it on your computer, at the root of the project, with the GitHub CLI
# (gh) signed in. It can be run again at any time: a secret that exists is
# kept unless --replace-token is given, and the ruleset, named
# "agent-kit: main", is updated in place. Each --check names a required
# check, in place of the default ones. --dir names the project when the
# script runs from elsewhere (the kit's install.sh does).
#
# The token is read from the variable CLAUDE_CODE_OAUTH_TOKEN, or typed at
# the terminal without being shown. It goes from memory to `gh secret set`
# through a pipe: never to a file, never on a command line.
#
# A personal account cannot approve its own pull request, so the ruleset
# asks for no approval count; the repository's admins (the owner) may merge
# a pull request that waits for a Code Owner with the bypass, knowing why.
# GitHub Free has no rulesets for private repositories: the script then
# says so, and the review still comments on every pull request.

set -euo pipefail

DIR=$(dirname "$0")/.. REPO= CHECKS= REPLACE=0 TOKEN_STEP=1 RULES_STEP=1 DRY=0
RULESET_NAME='agent-kit: main'
while [ $# -gt 0 ]; do
    case "$1" in
        --repo) REPO=$2; shift 2 ;;
        --check) CHECKS=$CHECKS$2$'\n'; shift 2 ;;
        --replace-token) REPLACE=1; shift ;;
        --no-token) TOKEN_STEP=0; shift ;;
        --no-rules) RULES_STEP=0; shift ;;
        --dir) DIR=$2; shift 2 ;;
        --dry-run) DRY=1; shift ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done
cd "$DIR"

say() { printf '%s\n' "$*"; }
die() { printf 'setup-github.sh: %s\n' "$*" >&2; exit 1; }
interactive() { [ -t 0 ] && [ "$DRY" = 0 ]; }

command -v gh >/dev/null || die 'the GitHub CLI is not installed: https://cli.github.com (then run: gh auth login)'
if ! gh auth status >/dev/null 2>&1; then
    if interactive; then
        say 'The GitHub CLI is not signed in. Signing in now (gh auth login):'
        gh auth login
    else
        die 'the GitHub CLI is not signed in: run gh auth login'
    fi
fi

if [ -z "$REPO" ]; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) \
        || die 'no GitHub repository found here; give it with --repo owner/name'
fi
[[ "$REPO" =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9._-]+$ ]] || die "--repo \"$REPO\" is not owner/name"
say "Repository: $REPO"

# 1. The token of the owner's Claude plan, as a secret of the repository.
token_step() {
    if gh secret list --repo "$REPO" 2>/dev/null | grep -q '^CLAUDE_CODE_OAUTH_TOKEN[[:space:]]' \
        && [ "$REPLACE" = 0 ]; then
        say 'Secret CLAUDE_CODE_OAUTH_TOKEN: already set, kept (--replace-token to replace it).'
        return
    fi
    local token=${CLAUDE_CODE_OAUTH_TOKEN:-}
    if [ -z "$token" ]; then
        if ! interactive; then
            say 'Secret CLAUDE_CODE_OAUTH_TOKEN: skipped (no terminal to type it; run this script again in one,'
            say '  or set the variable CLAUDE_CODE_OAUTH_TOKEN for it).'
            return
        fi
        say ''
        say 'The automatic review runs on your Claude Pro or Max plan. It needs the token'
        say 'that "claude setup-token" prints, after you sign in with that account.'
        if command -v claude >/dev/null; then
            local answer
            read -r -p 'Run "claude setup-token" now? [Y/n]: ' answer
            if [[ ! "$answer" =~ ^[nN] ]]; then
                claude setup-token || say '(claude setup-token did not finish; paste a token you already have, or leave empty)'
            fi
        else
            say 'Claude Code is not installed here: run "claude setup-token" where it is.'
        fi
        read -r -s -p 'Paste the token (it is not shown; empty to skip): ' token
        say ''
    fi
    token=$(printf '%s' "$token" | tr -d '[:space:]')
    if [ -z "$token" ]; then
        say 'Secret CLAUDE_CODE_OAUTH_TOKEN: skipped, no token given.'
        return
    fi
    if [[ "$token" != sk-ant-oat* ]]; then
        say 'This does not look like a token of "claude setup-token" (they start with sk-ant-oat).'
        local answer=n
        interactive && read -r -p 'Save it anyway? [y/N]: ' answer
        [[ "$answer" =~ ^[yY] ]] || { say 'Secret CLAUDE_CODE_OAUTH_TOKEN: not saved.'; return; }
    fi
    if [ "$DRY" = 1 ]; then
        say 'would: save the secret CLAUDE_CODE_OAUTH_TOKEN'
        return
    fi
    printf '%s' "$token" | gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo "$REPO" >/dev/null
    say 'Secret CLAUDE_CODE_OAUTH_TOKEN: saved. It lasts about a year; then run this script with --replace-token.'
}

# 2. The ruleset of the default branch.
rules_step() {
    if [ -z "$CHECKS" ]; then
        # One name per line: a job's name may hold commas.
        CHECKS=Review$'\n'
        # The job of the template's checks.yml, when the project still has it.
        local rules_job='Backlog, dashboard, pages, records and licences'
        if grep -qsF "name: $rules_job" .github/workflows/checks.yml .github/workflows/kit-checks.yml; then
            CHECKS=$CHECKS$rules_job$'\n'
        fi
    fi
    [ -f .github/CODEOWNERS ] || say 'Note: there is no .github/CODEOWNERS here, so no file waits for the owner (docs/kit.md).'
    local body
    body=$(CHECKS=$CHECKS NAME=$RULESET_NAME python3 - <<'PY'
import json, os
checks = [c.strip() for c in os.environ['CHECKS'].splitlines() if c.strip()]
print(json.dumps({
    'name': os.environ['NAME'],
    'target': 'branch',
    'enforcement': 'active',
    'conditions': {'ref_name': {'include': ['~DEFAULT_BRANCH'], 'exclude': []}},
    # The repository's admins (the owner) may merge a pull request that
    # waits for them, through the pull request only: never a direct push.
    'bypass_actors': [{'actor_id': 5, 'actor_type': 'RepositoryRole', 'bypass_mode': 'pull_request'}],
    'rules': [
        {'type': 'deletion'},
        {'type': 'non_fast_forward'},
        {'type': 'pull_request', 'parameters': {
            'required_approving_review_count': 0,   # a personal account cannot approve its own
            'require_code_owner_review': True,       # .github/ and the review's judge wait for the owner
            'dismiss_stale_reviews_on_push': False,
            'require_last_push_approval': False,
            'required_review_thread_resolution': False}},
        {'type': 'required_status_checks', 'parameters': {
            'strict_required_status_checks_policy': False,
            'required_status_checks': [{'context': c} for c in checks]}},
    ],
}))
PY
)
    local id action=created
    id=$(gh api "repos/$REPO/rulesets?includes_parents=false" --jq ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>/dev/null | head -n 1 || true)
    [ -z "$id" ] || action=updated
    if [ "$DRY" = 1 ]; then
        say "would: save ($action) the ruleset \"$RULESET_NAME\" requiring: ${CHECKS//$'\n'/; }"
        return
    fi
    local out
    if [ -n "$id" ]; then
        out=$(printf '%s' "$body" | gh api -X PUT "repos/$REPO/rulesets/$id" --input - 2>&1 >/dev/null) || rules_failed "$out"
    else
        out=$(printf '%s' "$body" | gh api -X POST "repos/$REPO/rulesets" --input - 2>&1 >/dev/null) || rules_failed "$out"
    fi
    [ -n "${RULES_FAILED:-}" ] && return
    say "Ruleset \"$RULESET_NAME\": $action. Changes to the default branch need a pull request"
    say "  whose checks pass (${CHECKS//$'\n'/; }); a change to the files of CODEOWNERS waits for the owner."
}
rules_failed() {
    RULES_FAILED=1
    if grep -qiE 'upgrade to github pro|make this repository public' <<<"$1"; then
        say 'Ruleset: not available. GitHub Free has no rules for private repositories.'
        say '  The review still runs and comments on every pull request, but cannot stop a merge.'
        say '  To have it stop one, make the repository public or move to GitHub Pro, and run this script again.'
    else
        say "Ruleset: GitHub refused it: $1"
        say '  Set it by hand as docs/kit.md, "The automatic review", says, or run this script again.'
    fi
}

[ "$TOKEN_STEP" = 0 ] || token_step
[ "$RULES_STEP" = 0 ] || rules_step
say 'Done.'
