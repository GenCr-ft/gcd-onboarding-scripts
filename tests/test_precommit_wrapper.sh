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

# stage <name> — a fresh fixture workspace with one REAL git repo and a linter present
#
# `git init`, not `mkdir -p .git/hooks`. The first version of this helper faked the repo, and
# AC-3 failed as a result: `pre-commit install` refuses a directory that is not a real
# repository ("FatalError: git failed. Is it installed, and are you in a Git repository
# directory?"). That read exactly like the implementation not writing the hook. A fixture that
# is not the thing under test produces a failure that looks like a defect.
stage() {
  WS="$TEST_HOME/$1"; rm -rf "$WS"
  export GFT_PROJECTS_HOME="$WS"
  mkdir -p "$WS/repo" "$WS/linters"
  git -C "$WS/repo" init -q
  git -C "$WS/repo" config user.email a@b
  git -C "$WS/repo" config user.name a
  printf '#!/usr/bin/env python3\nimport sys\nsys.exit(0)\n' > "$WS/linters/validate_planning_metadata.py"
  chmod +x "$WS/linters/validate_planning_metadata.py"
  HOOKS="$WS/repo/.git/hooks"
}

echo "=== AC-1 (MUST-FIRE): a clone that never ran 'pre-commit install' must not pass everything ==="
stage ac1
printf 'repos:\n  - repo: local\n    hooks:\n      - id: x\n' > "$WS/repo/.pre-commit-config.yaml"
deploy_planning_metadata_hook >/dev/null 2>&1
# BEHAVIOURAL, not textual. The first version of this arm grepped the wrapper for a bare
# `exit 0` line -- which the CORRECT v2 wrapper also contains, legitimately, for the
# no-config case. A static text match would therefore have failed a working fix, and it was
# asserting on the file's prose rather than on what the hook does.
#
# Instead: put a stub `pre-commit` on PATH that FAILS, in a repo that declares a config and
# has no legacy hook. A wrapper that runs the declared set propagates that failure; a wrapper
# that fails open exits 0 and the declared set never runs.
mkdir -p "$TEST_HOME/stub-fail"
printf '#!/usr/bin/env bash\necho "STUB pre-commit ran" >&2\nexit 1\n' > "$TEST_HOME/stub-fail/pre-commit"
chmod +x "$TEST_HOME/stub-fail/pre-commit"
out=$(cd "$WS/repo" && PATH="$TEST_HOME/stub-fail:$PATH" "$HOOKS/pre-commit" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "STUB pre-commit ran"; then
  ok "wrapper runs the declared set when no legacy hook exists"
elif [ "$rc" -eq 0 ]; then
  bad "wrapper runs the declared set when no legacy hook exists" "exit 0 -- failed OPEN, the declared set never ran"
else
  bad "wrapper runs the declared set when no legacy hook exists" "rc=$rc but the declared set was not invoked"
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

echo "=== AC-3 (MUST-FIRE): the commit-msg stage must be installed, and ONLY that one ==="
stage ac3
# A STUB `pre-commit`, not the real one. The real binary cannot run here at all: its shebang is
# /usr/bin/python3 and its module lives under ~/.local/lib, so the hermetic HOME every test in
# this repo uses makes it `ModuleNotFoundError: No module named 'pre_commit'`. An arm depending
# on it fails for a reason that has nothing to do with the code under test -- which is exactly
# how this arm first read as "nothing writes it" when the generator was in fact working.
#
# The stub records its argv, which lets this arm assert something stronger than the file
# appearing: that the generator asks for `commit-msg` and NEVER for `pre-commit`. Installing the
# pre-commit type is what moves the wrapper to .legacy and creates the self-call loop, so
# "which hook type was requested" is a security property, not a detail.
mkdir -p "$TEST_HOME/stub-pc"
cat > "$TEST_HOME/stub-pc/pre-commit" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${STUB_ARGV_LOG}"
hook=""
prev=""
for a in "$@"; do
  [ "$prev" = "--hook-type" ] && hook="$a"
  prev="$a"
done
if [ "${1:-}" = "install" ] && [ -n "$hook" ]; then
  d="$(git rev-parse --git-path hooks 2>/dev/null || echo .git/hooks)"
  mkdir -p "$d"
  printf '#!/usr/bin/env bash\n# stub %s hook\nexit 0\n' "$hook" > "$d/$hook"
  chmod +x "$d/$hook"
fi
exit 0
STUB
chmod +x "$TEST_HOME/stub-pc/pre-commit"
export STUB_ARGV_LOG="$TEST_HOME/ac3-argv.log"; : > "$STUB_ARGV_LOG"
( export PATH="$TEST_HOME/stub-pc:$PATH"; deploy_planning_metadata_hook >/dev/null 2>&1 )
if [ ! -f "$HOOKS/commit-msg" ]; then
  bad ".git/hooks/commit-msg exists after deployment" "nothing writes it"
elif ! grep -q -- "--hook-type commit-msg" "$STUB_ARGV_LOG"; then
  bad ".git/hooks/commit-msg exists after deployment" "the file appeared but commit-msg was never requested"
else
  ok ".git/hooks/commit-msg exists after deployment"
fi
if grep -q -- "--hook-type pre-commit" "$STUB_ARGV_LOG"; then
  bad "the pre-commit hook type is NEVER installed (recursion hazard)" "it was requested — this recreates the self-call loop"
else
  ok "the pre-commit hook type is NEVER installed (recursion hazard)"
fi

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

# ==============================================================================
# WI-272 — the gate's verdict depended on PATH, and a crash printed as a verdict
# ==============================================================================
#
# Step 1 of the wrapper executed the linter as a bare executable, so its interpreter came
# from `#!/usr/bin/env python3` -> PATH. Two symptoms, ONE defect: a crash and a genuine
# violation BOTH exit 1, so "could not run" cannot be recovered after invocation and has
# to be established before it. That is why the diagnosis fix and the interpreter fix are
# the same change.
#
# On the environment these arms assume: the CANNOT-RUN path fires only when NO candidate
# interpreter can import the linter's requirement. `/usr/bin/python3` is a fixed candidate
# and carries PyYAML on the dev machine and on the self-hosted runner CI uses, so the arms
# below reach that path with GFT_LINTER_REQUIRED_MODULE -- a requirement nothing can
# satisfy -- rather than by trying to strip PyYAML off the machine.
#
# Every arm re-stages via `stage`, so GFT_PROJECTS_HOME is always a fresh fixture under
# the hermetic HOME.

# stage_entry — an installed console-script entry point beside the fixture's linter,
# mirroring gcd-ops-scripts' real layout (<clone>/.venv/bin/validate-planning-metadata).
# The real one's shebang is an ABSOLUTE interpreter path, which is precisely why it ignores
# PATH; this stub stands in for that property by announcing itself.
stage_entry() {
  local d="$WS/gcd-ops-scripts/.venv/bin"
  mkdir -p "$d"
  printf '#!/usr/bin/env bash\necho "RAN=entrypoint"\nexit 0\n' > "$d/validate-planning-metadata"
  chmod +x "$d/validate-planning-metadata"
}

# broken_python <dir> — a `python3` that cannot run the linter, failing on the import
# exactly as the yaml-less poetry interpreter on the dev machine does. Staged rather than
# inherited: an arm that relied on the ambient PATH happening to put a broken interpreter
# first would itself be the environment-dependence this WI removes.
broken_python() {
  mkdir -p "$1"
  cat > "$1/python3" <<'BROKEN'
#!/usr/bin/env bash
# `-c` is the importability probe: this interpreter fails every one.
if [ "${1:-}" = "-c" ]; then exit 1; fi
echo "ModuleNotFoundError: No module named 'yaml'" >&2
exit 1
BROKEN
  chmod +x "$1/python3"
}

echo "=== AC-272.1 (MUST-FIRE): an unrunnable linter reads as 'cannot run', not 'failed' ==="
stage w272a
( export GFT_LINTER_REQUIRED_MODULE="gft_no_such_module_272"
  deploy_planning_metadata_hook >/dev/null 2>&1 )
out=$(cd "$WS/repo" && "$HOOKS/pre-commit" 2>&1); rc=$?
if printf '%s' "$out" | grep -qi 'validation failed'; then
  bad "an unrunnable gate does not report a validation failure" \
      "said 'validation failed' — the crash is still dressed as a verdict"
elif printf '%s' "$out" | grep -q 'gft_no_such_module_272' \
  && printf '%s' "$out" | grep -q 'python3'; then
  ok "an unrunnable gate does not report a validation failure"
else
  bad "an unrunnable gate does not report a validation failure" \
      "names neither the requirement nor an interpreter: $(printf '%s' "$out" | tr '\n' '|' | cut -c1-140)"
fi

echo "=== AC-272.2 (MUST-FIRE): it still refuses the commit, distinguishably ==="
# Same staging as AC-272.1, asserted separately because the two regress apart: a message
# fix that quietly returned 0 would satisfy AC-272.1 and defeat the gate entirely.
if [ "$rc" -eq 0 ]; then
  bad "an unrunnable gate refuses the commit with a code distinct from a verdict" \
      "exit 0 — a broken gate was turned into a passing one"
elif [ "$rc" -eq 1 ]; then
  bad "an unrunnable gate refuses the commit with a code distinct from a verdict" \
      "rc=1 — indistinguishable from a content verdict"
else
  ok "an unrunnable gate refuses the commit with a code distinct from a verdict"
fi

echo "=== AC-272.3 (MUST-FIRE): the linter executed is identical under two PATH orderings ==="
stage w272c
stage_entry
# Two distinct `python3`s, each announcing itself. Today the wrapper reaches the linter
# through `#!/usr/bin/env python3`, so whichever leads PATH is what runs, and the two runs
# disagree. With the entry point consumed, PATH plays no part.
for d in A B; do
  mkdir -p "$TEST_HOME/py272$d"
  printf '#!/usr/bin/env bash\necho "RAN=%s"\nexit 0\n' "$d" > "$TEST_HOME/py272$d/python3"
  chmod +x "$TEST_HOME/py272$d/python3"
done
deploy_planning_metadata_hook >/dev/null 2>&1
o1=$(cd "$WS/repo" && PATH="$TEST_HOME/py272A:$PATH" "$HOOKS/pre-commit" 2>&1); r1=$?
o2=$(cd "$WS/repo" && PATH="$TEST_HOME/py272B:$PATH" "$HOOKS/pre-commit" 2>&1); r2=$?
l1=$(printf '%s\n' "$o1" | grep '^RAN=' | head -1)
l2=$(printf '%s\n' "$o2" | grep '^RAN=' | head -1)
# `-n "$l1"` is not decoration: without it, two runs that both printed nothing would
# compare equal and this arm would pass having observed no linter at all.
if [ -n "$l1" ] && [ "$l1" = "$l2" ] && [ "$r1" = "$r2" ]; then
  ok "the linter executed, and the verdict, are PATH-independent"
else
  bad "the linter executed, and the verdict, are PATH-independent" \
      "run1=[${l1:-<none>} rc=$r1] run2=[${l2:-<none>} rc=$r2]"
fi

echo "=== AC-272.4 (MUST-FIRE): a yaml-less python3 leading PATH no longer blocks a clean commit ==="
# The reported bug, reproduced end to end. The broken interpreter leads PATH at BOTH
# generation and commit time, so this also proves generation-time resolution is not
# poisoned by whatever happened to lead PATH during onboarding.
stage w272d
broken_python "$TEST_HOME/py272broken"
( export PATH="$TEST_HOME/py272broken:$PATH"
  deploy_planning_metadata_hook >/dev/null 2>&1 )
out=$(cd "$WS/repo" && PATH="$TEST_HOME/py272broken:$PATH" "$HOOKS/pre-commit" 2>&1); rc=$?
if [ "$rc" -eq 0 ]; then
  ok "a compliant commit survives a yaml-less interpreter at the head of PATH"
else
  bad "a compliant commit survives a yaml-less interpreter at the head of PATH" \
      "rc=$rc out=$(printf '%s' "$out" | tr '\n' '|' | cut -c1-140)"
fi

echo "=== AC-272.7 (MUST-FIRE): a broken entry point is 'cannot run', not a verdict ==="
# The entry point is now the PRIMARY path, so a venv whose interpreter has been moved or
# deleted is the likeliest residual failure -- and bash reports it as 126/127, which without
# this branch would be relabelled "validation failed": the original defect, one layer in.
# Staged by giving the entry-point stub a shebang pointing at an interpreter that is not
# there, which is exactly what a deleted venv looks like.
stage w272g
mkdir -p "$WS/gcd-ops-scripts/.venv/bin"
printf '#!%s/gcd-ops-scripts/.venv/bin/python\nprint("unreachable")\n' "$WS" \
  > "$WS/gcd-ops-scripts/.venv/bin/validate-planning-metadata"
chmod +x "$WS/gcd-ops-scripts/.venv/bin/validate-planning-metadata"
deploy_planning_metadata_hook >/dev/null 2>&1
out=$(cd "$WS/repo" && "$HOOKS/pre-commit" 2>&1); rc=$?
if printf '%s' "$out" | grep -qi 'validation failed'; then
  bad "a broken entry point reads as 'cannot run'" \
      "said 'validation failed' — an exec failure is dressed as a verdict"
elif [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ] && printf '%s' "$out" | grep -qi 'cannot run'; then
  ok "a broken entry point reads as 'cannot run'"
else
  bad "a broken entry point reads as 'cannot run'" \
      "rc=$rc out=$(printf '%s' "$out" | tr '\n' '|' | cut -c1-140)"
fi

echo "=== AC-272.5 (MUST-NOT-FIRE): a genuine violation still reports as a validation failure ==="
stage w272e
printf '#!/usr/bin/env python3\nimport sys\nsys.exit(1)\n' > "$WS/linters/validate_planning_metadata.py"
chmod +x "$WS/linters/validate_planning_metadata.py"
deploy_planning_metadata_hook >/dev/null 2>&1
out=$(cd "$WS/repo" && "$HOOKS/pre-commit" 2>&1); rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -qi 'validation failed'; then
  ok "a genuine violation still reports as a validation failure, exit 1"
else
  bad "a genuine violation still reports as a validation failure, exit 1" \
      "rc=$rc out=$(printf '%s' "$out" | tr '\n' '|' | cut -c1-140)"
fi

echo "=== AC-272.6 (MUST-NOT-FIRE): the deployer still exits 0 on success ==="
# Guards tests/test_workspace_files.sh:141 from here, where the generator is changed.
stage w272f
if deploy_planning_metadata_hook >/dev/null 2>&1; then
  ok "deploy_planning_metadata_hook exits 0 on success"
else
  bad "deploy_planning_metadata_hook exits 0 on success" \
      "non-zero — folding a new failure into the return code breaks test_workspace_files.sh:141"
fi

echo
echo "  passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
