#!/usr/bin/env bash

# ==============================================================================
# WI-268 — the pre-commit wrapper fails open, and commit-msg is never installed
# ==============================================================================
#
# Two defects in `deploy_planning_metadata_hook`, plus a third that makes them
# unrepairable by re-running onboarding:
#
#   1. FAILS OPEN. The wrapper delegates to `pre-commit.legacy` if present and
#      `exit 0`s otherwise. Legacy exists only where an existing hook was moved
#      aside, so a clone where `pre-commit install` never ran gets exit 0 by
#      default. Measured across the 34 workspace clones: 30 carry the wrapper
#      with no legacy, and exactly ONE runs its declared set — the clone where
#      `pre-commit install` DISPLACED the wrapper into `.legacy`.
#   2. The commit-msg stage is never installed. 0 of 34. Nothing writes it, and
#      `pre-commit run --all-files` skips commit-msg-stage hooks by design, so
#      the documented manual check reports green over a set excluding commitlint.
#   3. The skip branch greps a marker with NO VERSION, so the exact population
#      that needs repair — wrapper present, no legacy — is the population it
#      skips. This is why the versioned marker must land before anything else.
#
# Convention: this file sources the includes and calls the function directly,
# as tests/test_onboarding_logic.sh does. An earlier revision claimed a dispatch
# entry point was required for testability; that was measured and refuted —
# sourcing works, and a nonexistent function exits 127 loudly rather than 0.
#
# EVERY arm runs against a staged fixture workspace under a hermetic HOME. The
# generator iterates children of GFT_PROJECTS_HOME containing .git; an arm that
# forgot to override it would deploy hooks into the developer's real clones.

set -uo pipefail

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true
export SCRIPT_DIR="$PROJECT_ROOT"

TEST_HOME=$(mktemp -d -t wi268-XXXXXX)
export HOME="$TEST_HOME"
trap 'rm -rf "$TEST_HOME"' EXIT

source "${PROJECT_ROOT}/includes/00_bootstrap.sh" >/dev/null 2>&1 || true
source "${PROJECT_ROOT}/includes/01_helpers.sh"  >/dev/null 2>&1 || true
source "${PROJECT_ROOT}/includes/06_workspace_files.sh"

PASS=0; FAIL=0
MARK="GenCr@ft Studio - Chained Pre-Commit Hook wrapper"

ok()   { PASS=$((PASS+1)); printf '  ok    %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '          %s\n' "$2"; }
check(){ if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "want=$3 got=$2"; fi; }

# stage <name> — a fresh fixture workspace with one git repo and a linter present
stage() {
  WS="$TEST_HOME/$1"; rm -rf "$WS"
  export GFT_PROJECTS_HOME="$WS"
  mkdir -p "$WS/repo/.git/hooks" "$WS/linters"
  printf '#!/usr/bin/env python3\nimport sys\nsys.exit(0)\n' > "$WS/linters/validate_planning_metadata.py"
  chmod +x "$WS/linters/validate_planning_metadata.py"
  HOOKS="$WS/repo/.git/hooks"
}

echo "=== AC-1 (MUST-FIRE): a clone that never ran 'pre-commit install' must not pass everything ==="
stage ac1
printf 'repos:\n  - repo: local\n    hooks:\n      - id: x\n' > "$WS/repo/.pre-commit-config.yaml"
deploy_planning_metadata_hook >/dev/null 2>&1
# No legacy hook exists, so a fail-open wrapper reaches `exit 0` regardless of the declared set.
if grep -qE '^\s*exit 0\s*$' "$HOOKS/pre-commit" 2>/dev/null; then
  bad "wrapper does not fail open when no legacy hook exists" "the wrapper ends in a bare 'exit 0'"
else
  ok "wrapper does not fail open when no legacy hook exists"
fi

echo "=== AC-2 (MUST-FIRE): a v1 wrapper with no legacy must be REWRITTEN, not skipped ==="
stage ac2
# Simulate the fleet's real state: our v1 wrapper in place, no legacy beside it.
printf '#!/usr/bin/env bash\n# %s\n# v1 body\nexit 0\n' "$MARK" > "$HOOKS/pre-commit"
chmod +x "$HOOKS/pre-commit"
before=$(sha256sum "$HOOKS/pre-commit" | cut -d' ' -f1)
deploy_planning_metadata_hook >/dev/null 2>&1
after=$(sha256sum "$HOOKS/pre-commit" | cut -d' ' -f1)
if [ "$before" = "$after" ]; then
  bad "a v1 wrapper with no legacy is rewritten" "byte-identical after deployment — the skip branch skipped it"
else
  ok "a v1 wrapper with no legacy is rewritten"
fi

echo "=== AC-3 (MUST-FIRE): the commit-msg stage must be installed ==="
stage ac3
deploy_planning_metadata_hook >/dev/null 2>&1
if [ -f "$HOOKS/commit-msg" ]; then ok ".git/hooks/commit-msg exists after deployment"
else bad ".git/hooks/commit-msg exists after deployment" "nothing writes it"; fi

echo "=== AC-5 (MUST-FIRE): a delegate carrying the wrapper's own marker must be refused ==="
stage ac5
deploy_planning_metadata_hook >/dev/null 2>&1
# Reproduce the live precondition found in gencr-ft.github.io: our wrapper sitting AT the
# legacy path. A wrapper that delegates blindly here invokes itself, unbounded.
cp "$HOOKS/pre-commit" "$HOOKS/pre-commit.legacy"
out=$(timeout 10 "$HOOKS/pre-commit" 2>&1); rc=$?
if [ "$rc" -eq 124 ]; then
  bad "self-delegation is refused rather than recursing" "timed out — the wrapper called itself"
elif printf '%s' "$out" | grep -qiE 'refus|itself|recurs|self'; then
  ok "self-delegation is refused rather than recursing"
else
  bad "self-delegation is refused rather than recursing" "no refusal message; rc=$rc"
fi

echo "=== AC-6 (MUST-FIRE): config declared but pre-commit absent must fail CLOSED ==="
stage ac6
printf 'repos:\n  - repo: local\n    hooks:\n      - id: x\n' > "$WS/repo/.pre-commit-config.yaml"
deploy_planning_metadata_hook >/dev/null 2>&1
# An empty PATH stub directory: `pre-commit` is unavailable, config is present.
mkdir -p "$TEST_HOME/nopath"
out=$(cd "$WS/repo" && PATH="$TEST_HOME/nopath:/usr/bin:/bin" "$HOOKS/pre-commit" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qi 'pre-commit'; then
  ok "declared-but-unrunnable hook set fails closed, naming pre-commit"
else
  bad "declared-but-unrunnable hook set fails closed, naming pre-commit" "rc=$rc out=$(printf '%s' "$out" | head -c 90)"
fi

echo "=== AC-8 (MUST-NOT-FIRE / green-state guard): no config at all must exit 0 ==="
stage ac8
deploy_planning_metadata_hook >/dev/null 2>&1
out=$(cd "$WS/repo" && "$HOOKS/pre-commit" 2>&1); rc=$?
check "a repo declaring no hooks still commits" "$rc" "0"

echo "=== AC-9 (MUST-NOT-FIRE): a CURRENT-version wrapper with no legacy is skipped (idempotence) ==="
stage ac9
deploy_planning_metadata_hook >/dev/null 2>&1
first=$(sha256sum "$HOOKS/pre-commit" | cut -d' ' -f1)
deploy_planning_metadata_hook >/dev/null 2>&1
second=$(sha256sum "$HOOKS/pre-commit" | cut -d' ' -f1)
check "re-running onboarding does not rewrite a current wrapper" "$first" "$second"

echo
echo "  passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
