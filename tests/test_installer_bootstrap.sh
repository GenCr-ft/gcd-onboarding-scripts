#!/usr/bin/env bash
# ==============================================================================
# Test: installers self-bootstrap their version managers and degrade gracefully
# (WI-229). pyenv/nvm auto-install; prettier via npm; python falls back to a
# compatible system python3 instead of aborting onboarding.
# ==============================================================================
set -u
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true SCRIPT_DIR="$PROJECT_ROOT"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/00_bootstrap.sh"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/includes/02_installers.sh"

failed=0

# 1. install_python: pyenv absent + cannot compile → graceful fallback to system python3 (>=3.9 here)
t1() {
  local tmp; tmp=$(mktemp -d)
  # No pyenv anywhere; curl (pyenv.run) is a no-op so pyenv stays absent.
  curl() { return 0; }
  pyenv() { return 1; }   # any pyenv call fails
  ( HOME="$tmp" PYENV_ROOT="$tmp/.pyenv" install_python "3.99.99" >/dev/null 2>&1 )
  local rc=$?
  rm -rf "$tmp"; unset -f curl pyenv
  [[ $rc -eq 0 ]] || { echo "FAIL: install_python should fall back to system python3 and return 0 (got $rc)"; ((failed++)); }
}

# 2. install_prettier: installs via npm global
t2() {
  local log; log=$(mktemp)
  npm() { echo "npm $*" >>"$log"; return 0; }
  install_prettier >/dev/null 2>&1
  unset -f npm
  grep -q 'install -g prettier' "$log" || { echo "FAIL: install_prettier did not run 'npm install -g prettier'"; ((failed++)); }
  rm -f "$log"
}

# 3. install_node: nvm absent → auto-bootstrap via curl installer
t3() {
  local tmp; tmp=$(mktemp -d); local log; log=$(mktemp)
  curl() { echo "curl $*" >>"$log"; mkdir -p "$tmp/.nvm"; printf 'nvm(){ return 0; }\n' > "$tmp/.nvm/nvm.sh"; }
  ( HOME="$tmp" install_node "20.18.0" >/dev/null 2>&1 )
  unset -f curl
  grep -q 'nvm-sh/nvm' "$log" || { echo "FAIL: install_node did not auto-bootstrap nvm via curl"; ((failed++)); }
  rm -rf "$tmp" "$log"
}

# 4. _system_python_ok true here (CI/dev has python3 >= 3.9)
t4() { _system_python_ok || { echo "FAIL: _system_python_ok should be true in this env"; ((failed++)); }; }

t1; t2; t3; t4

if [[ $failed -ne 0 ]]; then echo "🔴 test_installer_bootstrap: $failed failed."; exit 1; fi
echo "✓ test_installer_bootstrap: all checks passed."
