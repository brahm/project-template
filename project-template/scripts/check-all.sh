#!/usr/bin/env bash
# SPDX-FileCopyrightText: {{YEAR}} {{PROJECT_NAME}} contributors
# SPDX-License-Identifier: {{LICENSE}}

# Runs every check of the CI on the working tree, in the same order, and
# stops at the first that fails. Run it once before opening or updating a
# pull request. Add the checks of your language (format, lint, tests,
# documentation with warnings as errors) where the comment says.

set -euo pipefail
cd "$(dirname "$0")/.."

step() {
    printf '\n==> %s\n' "$1"
}

# --- The checks of the project's language go here, for example:
# step 'Formatting';    cargo fmt --all --check
# step 'Lint';          cargo clippy --all-targets -- --deny warnings
# step 'Tests';         cargo test
# step 'Documentation'; RUSTDOCFLAGS='--deny warnings' cargo doc --no-deps

step 'Backlog register'
python3 scripts/check-backlog.py

step 'Dashboard sources'
python3 scripts/dashboard.py --check

if command -v reuse >/dev/null; then
    step 'REUSE compliance'
    reuse lint
else
    printf '\n(reuse is not installed: skipping the licence check; the CI runs it)\n'
fi

printf '\nAll checks passed.\n'
