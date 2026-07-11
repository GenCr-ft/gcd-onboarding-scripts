#!/usr/bin/env bash
# ==============================================================================
# Test: WI-384b — shared-tooling migration to studio_home() (~/.gft-studio).
#   - studio_home(): default + GFT_STUDIO_HOME override
#   - bootstrap_shared_tooling(): clone / pull / reclone branches (setup_ssot
#     git pattern, NOT `[[ -d ]] || clone`), idempotent per ENG-ADR-088 §8
#   - warn_legacy_gft_studio(): fires exactly once per shell when ~/gft_studio
#     exists, silent otherwise
# ==============================================================================
set -u
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true SCRIPT_DIR="$PROJECT_ROOT"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/01_helpers.sh"

failed=0
fail() { echo "FAIL: $1"; ((failed++)); }

# --- Build a fake gh/git bin dir that simulates clone/pull without network. ----
FAKE_BIN=$(mktemp -d)
CALLLOG="$FAKE_BIN/calls.log"
: > "$CALLLOG"
cat > "$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$CALLLOG"
if [[ "$1" == "repo" && "$2" == "clone" ]]; then
  target="$4"        # gh repo clone <slug> <target>
  mkdir -p "$target/.git"
  printf 'cloned\n' > "$target/CLONED_MARKER"
fi
exit 0
EOF
cat > "$FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
echo "git $*" >> "$CALLLOG"
if [[ "$1" == "clone" ]]; then
  target="${@: -1}"  # git clone <url> <target>
  mkdir -p "$target/.git"
  printf 'cloned\n' > "$target/CLONED_MARKER"
elif [[ "$1" == "-C" && "$3" == "pull" ]]; then
  : # pull is a no-op success
fi
exit 0
EOF
chmod +x "$FAKE_BIN/gh" "$FAKE_BIN/git"  # noqa: S103 (test fixture stubs)
export CALLLOG

SHARED=(gcs-plt-tools gcs-plt-gemop gcs-core-governance)

# ------------------------------------------------------------------ studio_home
h1=$(mktemp -d)
got=$( HOME="$h1" bash -c "source '$PROJECT_ROOT/includes/00_bootstrap.sh'; source '$PROJECT_ROOT/includes/01_helpers.sh'; studio_home" )
[[ "$got" == "$h1/.gft-studio" ]] || fail "studio_home default expected '$h1/.gft-studio', got '$got'"

got=$( HOME="$h1" GFT_STUDIO_HOME="/custom/home" bash -c "source '$PROJECT_ROOT/includes/00_bootstrap.sh'; source '$PROJECT_ROOT/includes/01_helpers.sh'; studio_home" )
[[ "$got" == "/custom/home" ]] || fail "studio_home override expected '/custom/home', got '$got'"

# ------------------------------------------------- bootstrap: clone branch (new)
h2=$(mktemp -d)
( PATH="$FAKE_BIN:$PATH" HOME="$h2" bootstrap_shared_tooling >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 0 ]] || fail "bootstrap_shared_tooling (clone) rc=$rc"
for r in "${SHARED[@]}"; do
  [[ -d "$h2/.gft-studio/$r/.git" ]] || fail "clone branch: $r not cloned into studio_home"
done

# ----------------------------------------- bootstrap: pull branch (existing git)
h3=$(mktemp -d)
: > "$CALLLOG"
mkdir -p "$h3/.gft-studio/gcs-plt-tools/.git"
printf 'preexisting\n' > "$h3/.gft-studio/gcs-plt-tools/SENTINEL"
( PATH="$FAKE_BIN:$PATH" HOME="$h3" bootstrap_shared_tooling >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 0 ]] || fail "bootstrap_shared_tooling (pull) rc=$rc"
[[ -f "$h3/.gft-studio/gcs-plt-tools/SENTINEL" ]] || fail "pull branch: existing repo was reclobbered (SENTINEL lost)"
grep -q "git -C $h3/.gft-studio/gcs-plt-tools pull" "$CALLLOG" || fail "pull branch: did not run 'git -C … pull' for existing repo"
# The other two repos are absent here → must still be cloned (loop must not skip
# them after the pull-branch `continue`).
for r in gcs-plt-gemop gcs-core-governance; do
  [[ -d "$h3/.gft-studio/$r/.git" ]] || fail "pull branch: absent repo '$r' was not cloned alongside the pulled one"
done

# ------------------------------ bootstrap: reclone branch (dir exists, not a git)
h4=$(mktemp -d)
mkdir -p "$h4/.gft-studio/gcs-plt-gemop"          # exists but NOT a git repo
printf 'junk\n' > "$h4/.gft-studio/gcs-plt-gemop/STALE"
( PATH="$FAKE_BIN:$PATH" HOME="$h4" bootstrap_shared_tooling >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 0 ]] || fail "bootstrap_shared_tooling (reclone) rc=$rc"
[[ ! -f "$h4/.gft-studio/gcs-plt-gemop/STALE" ]] || fail "reclone branch: stale non-git dir not removed before clone"
[[ -d "$h4/.gft-studio/gcs-plt-gemop/.git" ]] || fail "reclone branch: repo not re-cloned"

# --------------------------------------------------------- warn_legacy once-only
h5=$(mktemp -d); mkdir -p "$h5/gft_studio"
out=$( HOME="$h5" bash -c "source '$PROJECT_ROOT/includes/00_bootstrap.sh'; source '$PROJECT_ROOT/includes/01_helpers.sh'; warn_legacy_gft_studio; warn_legacy_gft_studio" 2>&1 )
# Count the unique WARN line ("Legacy workspace …"); the single call also emits a
# separate INFO hint line, so we must not match on the shared "gft_studio" token.
n=$(printf '%s\n' "$out" | grep -c 'Legacy workspace' || true)
[[ "$n" -eq 1 ]] || fail "warn_legacy_gft_studio should warn exactly once, warned $n times"

h6=$(mktemp -d)   # no legacy dir → silent
out=$( HOME="$h6" bash -c "source '$PROJECT_ROOT/includes/00_bootstrap.sh'; source '$PROJECT_ROOT/includes/01_helpers.sh'; warn_legacy_gft_studio" 2>&1 )
printf '%s\n' "$out" | grep -q 'Legacy workspace' && fail "warn_legacy_gft_studio warned when no legacy dir exists"

rm -rf "$FAKE_BIN" "$h1" "$h2" "$h3" "$h4" "$h5" "$h6"

if [[ $failed -ne 0 ]]; then echo "🔴 test_studio_home_migration: $failed failed."; exit 1; fi
echo "✓ test_studio_home_migration: all checks passed."
