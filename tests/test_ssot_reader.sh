#!/usr/bin/env bash
# Tests the real get_ssot_tool_version() against the mock_ssot fixture.
# test_onboarding_logic.sh mocks this function wholesale; this file
# exercises the real implementation with no overrides.
#
# Runs under set -euo pipefail to replicate the production shell environment
# that gft-onboarding.sh establishes before sourcing the helpers.

TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)

export TEST_ENV=true
export GFT_SSOT_PATH="${TEST_SCRIPT_PATH}/fixtures/mock_ssot"

set -euo pipefail

source "${PROJECT_ROOT}/includes/01_helpers.sh"

checks_failed=0
checks_passed=0

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        (( checks_passed++ )) || true
    else
        log_error "FAIL [$label]: expected '$expected', got '$actual'"
        (( checks_failed++ )) || true
    fi
}

# Happy path — each pinned tool returns the correct semver from the fixture.
assert_eq "nodejs"    "20.18.0" "$(get_ssot_tool_version nodejs)"
assert_eq "python"    "3.11.5"  "$(get_ssot_tool_version python)"
assert_eq "pnpm"      "8.6.0"   "$(get_ssot_tool_version pnpm)"
assert_eq "opentofu"  "1.6.0"   "$(get_ssot_tool_version opentofu)"

# Unhappy path — unknown tool must return empty string and exit 0 (|| true in function guards pipefail).
actual=$(get_ssot_tool_version "nonexistent-tool")
status=$?
assert_eq "unknown-tool-value"  "" "$actual"
assert_eq "unknown-tool-status" "0" "$status"

echo ""
echo "  ssot_reader: Passed: $checks_passed  Failed: $checks_failed"
[[ $checks_failed -eq 0 ]] && log_success "tests/test_ssot_reader.sh passed" && exit 0
log_error "tests/test_ssot_reader.sh FAILED ($checks_failed failure(s))"
exit 1
