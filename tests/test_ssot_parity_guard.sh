#!/usr/bin/env bash
# Tests the scheme guard in test_ssot_parity.sh.
# Each case runs the script in a subshell; no live network calls are made.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PARITY_SCRIPT="${SCRIPT_DIR}/test_ssot_parity.sh"

checks_failed=0
checks_passed=0

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    (( checks_passed++ )) || true
  else
    echo "  FAIL [$label]: expected exit $expected, got $actual" >&2
    (( checks_failed++ )) || true
  fi
}

assert_stderr_contains() {
  local label="$1" pattern="$2" output="$3"
  if printf '%s' "$output" | grep -qF "$pattern"; then
    (( checks_passed++ )) || true
  else
    echo "  FAIL [$label]: expected stderr to contain '$pattern'" >&2
    echo "  Actual output: $output" >&2
    (( checks_failed++ )) || true
  fi
}

assert_stderr_not_contains() {
  local label="$1" pattern="$2" output="$3"
  if ! printf '%s' "$output" | grep -qF "$pattern"; then
    (( checks_passed++ )) || true
  else
    echo "  FAIL [$label]: expected stderr NOT to contain '$pattern'" >&2
    (( checks_failed++ )) || true
  fi
}

# --- Cycle 1: invalid scheme → exit 1 with error message ---

output=$(SSOT_PARITY_REMOTE_URL="file:///etc/passwd" CROSS_REPO_PAT="dummy" \
  bash "$PARITY_SCRIPT" 2>&1) && actual_exit=$? || actual_exit=$?
assert_exit "invalid-scheme-exit-code" "1" "$actual_exit"
assert_stderr_contains "invalid-scheme-error-msg" \
  "[ERROR] REMOTE_URL must use https://raw.githubusercontent.com/ scheme" "$output"

# --- Cycle 2a: unset URL (default) → guard does not fire (exits 0 with [WARN]) ---

output=$(unset SSOT_PARITY_REMOTE_URL 2>/dev/null; CROSS_REPO_PAT="" \
  bash "$PARITY_SCRIPT" 2>&1) && actual_exit=$? || actual_exit=$?
assert_exit "default-url-exit-code" "0" "$actual_exit"
assert_stderr_not_contains "default-url-no-scheme-error" \
  "[ERROR] REMOTE_URL must use https://raw.githubusercontent.com/ scheme" "$output"

# --- Cycle 2b: valid https override → guard passes, exits 0 with [WARN] ---

output=$(SSOT_PARITY_REMOTE_URL="https://raw.githubusercontent.com/GenCr-ft/gcs-core-governance/feat/branch/tooling/ssot/.tool-versions-gft" \
  CROSS_REPO_PAT="" bash "$PARITY_SCRIPT" 2>&1) && actual_exit=$? || actual_exit=$?
assert_exit "valid-override-exit-code" "0" "$actual_exit"
assert_stderr_not_contains "valid-override-no-scheme-error" \
  "[ERROR] REMOTE_URL must use https://raw.githubusercontent.com/ scheme" "$output"

echo ""
echo "  ssot_parity_guard: Passed: $checks_passed  Failed: $checks_failed"
[[ $checks_failed -eq 0 ]] && echo "✓ tests/test_ssot_parity_guard.sh passed" && exit 0
echo "✗ tests/test_ssot_parity_guard.sh FAILED ($checks_failed failure(s))" >&2
exit 1
