#!/usr/bin/env bash
# Run the gcd-onboarding-scripts test suite.
#
# Usage:
#   ./test.sh        # discover and run all tests/test_*.sh files
#
# Exit: 0 = all tests passed, non-zero = failure
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR"

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      sed -n '2,7p' "$0" | sed 's/^# \?//'
      exit 0 ;;
  esac
done

echo "=== gcd-onboarding-scripts tests ==="

FAILED=0
TEST_COUNT=0

for test_file in tests/test_*.sh; do
  if [[ ! -f "$test_file" ]]; then
    echo "  Error: No test files found in tests/" >&2
    exit 1
  fi
  TEST_COUNT=$((TEST_COUNT + 1))
  echo "  Running $test_file ..."
  if bash "$test_file"; then
    echo "  ✓ $test_file passed"
  else
    echo "  ✗ $test_file failed" >&2
    FAILED=1
  fi
done

echo ""
if [[ "$FAILED" -eq 0 ]]; then
  echo "✓ All tests passed ($TEST_COUNT test file(s) run)."
else
  echo "✗ One or more tests failed." >&2
fi
exit "$FAILED"
