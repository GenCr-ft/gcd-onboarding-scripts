#!/usr/bin/env bash
# test_walking_skeleton_launcher.sh — TDD regression tests for run-walking-skeleton.sh
set -euo pipefail

TEST_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPO_ROOT=$(cd "${TEST_DIR}/.." && pwd)
LAUNCHER_SRC="${REPO_ROOT}/workspace/run-walking-skeleton.sh"

failures=0
passed=0

log_test() { echo "[TEST] $*"; }
fail() { echo "[FAIL] $*" >&2; ((failures++)) || true; return 1; }
ok() { echo "[OK] $*"; ((passed++)) || true; }

# Create a temporary workspace for mocking the launcher environment
setup_mock_workspace() {
  local ws_dir
  ws_dir=$(mktemp -d)
  
  # Stub directories
  mkdir -p "${ws_dir}/gcl-srv-authentication"
  mkdir -p "${ws_dir}/gcp-aethel-server"
  mkdir -p "${ws_dir}/gcl-voxel-engine"
  mkdir -p "${ws_dir}/.keys"
  
  # Create a mock gcl-voxel-engine/package.json
  cat > "${ws_dir}/gcl-voxel-engine/package.json" <<'EOF'
{
  "name": "@gencraft/gcl-voxel-engine",
  "version": "0.1.0",
  "main": "dist/index.js",
  "types": "dist/index.d.ts"
}
EOF

  # Mock trigger files/folders
  touch "${ws_dir}/gcl-srv-authentication/docker-compose.dev.yml"
  mkdir -p "${ws_dir}/gcl-voxel-engine/node_modules"
  mkdir -p "${ws_dir}/gcl-srv-authentication/node_modules"
  mkdir -p "${ws_dir}/gcp-aethel-server/node_modules"
  
  echo "$ws_dir"
}

# Setup mock PATH for command stubbing
setup_mock_path() {
  local mock_bin_dir real_node
  mock_bin_dir=$(mktemp -d)
  real_node=$(which node)
  
  # Stub openssl
  cat > "${mock_bin_dir}/openssl" <<'EOF'
#!/usr/bin/env bash
out_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -out)
      out_file="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
if [[ -n "$out_file" ]]; then
  echo "MOCK KEY CONTENT" > "$out_file"
fi
exit 0
EOF

  # Stub docker
  cat > "${mock_bin_dir}/docker" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  # Stub ss
  cat > "${mock_bin_dir}/ss" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  # Stub curl
  cat > "${mock_bin_dir}/curl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

  # Stub node
  cat > "${mock_bin_dir}/node" <<EOF
#!/usr/bin/env bash
if [[ "\$*" == *"-e"* ]]; then
  exec "${real_node}" "\$@"
elif [[ "\$*" == *"dist/main"* ]]; then
  sleep 100
fi
exit 0
EOF

  chmod +x "${mock_bin_dir}"/*
  echo "$mock_bin_dir"
}

# Test Case 1: Success Path
test_launcher_success_path() {
  log_test "Walking skeleton success path: builds voxel engine, validates entrypoints, then builds server"
  
  local ws_dir mock_bin
  ws_dir=$(setup_mock_workspace)
  mock_bin=$(setup_mock_path)
  
  # Populate valid entrypoints
  mkdir -p "${ws_dir}/gcl-voxel-engine/dist"
  touch "${ws_dir}/gcl-voxel-engine/dist/index.js"
  touch "${ws_dir}/gcl-voxel-engine/dist/index.d.ts"
  
  # Stub npm to record call order and exit 0
  local npm_log="${ws_dir}/npm_calls.log"
  cat > "${mock_bin}/npm" <<EOF
#!/usr/bin/env bash
echo "\$PWD: npm \$*" >> "${npm_log}"
exit 0
EOF
  chmod +x "${mock_bin}/npm"
  
  # Mock node is already set up in setup_mock_path
  
  # Run launcher in mock environment
  local out_log="${ws_dir}/launcher.log"
  (
    export PATH="${mock_bin}:${PATH}"
    export WORKSPACE="${ws_dir}"
    # Run the script, but stub the background waits to exit fast
    export seq="echo 1"
    export sleep="echo"
    bash "${LAUNCHER_SRC}" >"${out_log}" 2>&1
  ) || true # background trap might exit non-zero on mock teardown
  
  # Verify npm calls order
  if [[ ! -f "${npm_log}" ]]; then
    fail "Success Path: npm was not called"
    return 1
  fi
  
  local npm_calls
  npm_calls=$(cat "${npm_log}")
  
  # Check if gcl-voxel-engine was built before gcp-aethel-server
  if [[ "$npm_calls" != *"gcl-voxel-engine: npm run build"* ]]; then
    fail "Success Path: gcl-voxel-engine was not built"
    return 1
  fi
  if [[ "$npm_calls" != *"gcp-aethel-server: npm run build"* ]]; then
    fail "Success Path: gcp-aethel-server was not built"
    return 1
  fi
  
  # Voxel engine build must happen before server build
  local voxel_idx server_idx
  voxel_idx=$(grep -n "gcl-voxel-engine: npm run build" "${npm_log}" | cut -d: -f1)
  server_idx=$(grep -n "gcp-aethel-server: npm run build" "${npm_log}" | cut -d: -f1)
  
  if (( voxel_idx >= server_idx )); then
    fail "Success Path: gcl-voxel-engine must be built before gcp-aethel-server"
    return 1
  fi
  
  ok "Success Path: build order is correct and entrypoints validated"
  rm -rf "${ws_dir}" "${mock_bin}"
}

# Test Case 2: Voxel Build Failure
test_voxel_build_failure() {
  log_test "Fail-fast: voxel engine build failure stops launcher before server build"
  
  local ws_dir mock_bin
  ws_dir=$(setup_mock_workspace)
  mock_bin=$(setup_mock_path)
  
  local npm_log="${ws_dir}/npm_calls.log"
  cat > "${mock_bin}/npm" <<EOF
#!/usr/bin/env bash
echo "\$PWD: npm \$*" >> "${npm_log}"
if [[ "\$PWD" == *"gcl-voxel-engine"* && "\$*" == "run build" ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "${mock_bin}/npm"
  
  local out_log="${ws_dir}/launcher.log"
  local exit_code=0
  (
    export PATH="${mock_bin}:${PATH}"
    export WORKSPACE="${ws_dir}"
    bash "${LAUNCHER_SRC}" >"${out_log}" 2>&1
  ) && exit_code=$? || exit_code=$?
  
  if [[ "$exit_code" -eq 0 ]]; then
    fail "Voxel Build Failure: launcher exited with 0"
    return 1
  fi
  
  # Check diagnostics message
  if ! grep -q "ERROR: gcl-voxel-engine package build failed" "${out_log}"; then
    fail "Voxel Build Failure: missing diagnostic message. Log: $(cat "${out_log}")"
    return 1
  fi
  
  # Server build must NOT be called
  if grep -q "gcp-aethel-server: npm run build" "${npm_log}"; then
    fail "Voxel Build Failure: gcp-aethel-server build was attempted"
    return 1
  fi
  
  ok "Voxel Build Failure: fails fast with exact diagnostic and blocks server build"
  rm -rf "${ws_dir}" "${mock_bin}"
}

# Test Case 3: Missing Main Entrypoint
test_missing_main_entrypoint() {
  log_test "Fail-fast: missing package main entrypoint file blocks server build"
  
  local ws_dir mock_bin
  ws_dir=$(setup_mock_workspace)
  mock_bin=$(setup_mock_path)
  
  # Ensure types entrypoint exists but main is missing
  mkdir -p "${ws_dir}/gcl-voxel-engine/dist"
  touch "${ws_dir}/gcl-voxel-engine/dist/index.d.ts"
  
  local npm_log="${ws_dir}/npm_calls.log"
  cat > "${mock_bin}/npm" <<EOF
#!/usr/bin/env bash
echo "\$PWD: npm \$*" >> "${npm_log}"
exit 0
EOF
  chmod +x "${mock_bin}/npm"
  
  local out_log="${ws_dir}/launcher.log"
  local exit_code=0
  (
    export PATH="${mock_bin}:${PATH}"
    export WORKSPACE="${ws_dir}"
    bash "${LAUNCHER_SRC}" >"${out_log}" 2>&1
  ) && exit_code=$? || exit_code=$?
  
  if [[ "$exit_code" -eq 0 ]]; then
    fail "Missing Main Entrypoint: launcher exited with 0"
    return 1
  fi
  
  # Check diagnostics message
  if ! grep -q "ERROR: gcl-voxel-engine package main entrypoint missing: " "${out_log}"; then
    fail "Missing Main Entrypoint: missing diagnostic message. Log: $(cat "${out_log}")"
    return 1
  fi
  
  # Server build must NOT be called
  if grep -q "gcp-aethel-server: npm run build" "${npm_log}"; then
    fail "Missing Main Entrypoint: gcp-aethel-server build was attempted"
    return 1
  fi
  
  ok "Missing Main Entrypoint: fails fast with exact diagnostic and blocks server build"
  rm -rf "${ws_dir}" "${mock_bin}"
}

# Test Case 4: Missing Types Entrypoint
test_missing_types_entrypoint() {
  log_test "Fail-fast: missing package types entrypoint file blocks server build"
  
  local ws_dir mock_bin
  ws_dir=$(setup_mock_workspace)
  mock_bin=$(setup_mock_path)
  
  # Ensure main entrypoint exists but types is missing
  mkdir -p "${ws_dir}/gcl-voxel-engine/dist"
  touch "${ws_dir}/gcl-voxel-engine/dist/index.js"
  
  local npm_log="${ws_dir}/npm_calls.log"
  cat > "${mock_bin}/npm" <<EOF
#!/usr/bin/env bash
echo "\$PWD: npm \$*" >> "${npm_log}"
exit 0
EOF
  chmod +x "${mock_bin}/npm"
  
  local out_log="${ws_dir}/launcher.log"
  local exit_code=0
  (
    export PATH="${mock_bin}:${PATH}"
    export WORKSPACE="${ws_dir}"
    bash "${LAUNCHER_SRC}" >"${out_log}" 2>&1
  ) && exit_code=$? || exit_code=$?
  
  if [[ "$exit_code" -eq 0 ]]; then
    fail "Missing Types Entrypoint: launcher exited with 0"
    return 1
  fi
  
  # Check diagnostics message
  if ! grep -q "ERROR: gcl-voxel-engine package types entrypoint missing: " "${out_log}"; then
    fail "Missing Types Entrypoint: missing diagnostic message. Log: $(cat "${out_log}")"
    return 1
  fi
  
  # Server build must NOT be called
  if grep -q "gcp-aethel-server: npm run build" "${npm_log}"; then
    fail "Missing Types Entrypoint: gcp-aethel-server build was attempted"
    return 1
  fi
  
  ok "Missing Types Entrypoint: fails fast with exact diagnostic and blocks server build"
  rm -rf "${ws_dir}" "${mock_bin}"
}

test_smoke_exit_contract() {
  log_test "F1.5: --smoke-exit-after-spawn boot-proof contract (Forge, gcs-project-management#414)"
  local src="${LAUNCHER_SRC}"
  local pass_all=1

  # Launcher must remain syntactically valid.
  if ! bash -n "${src}" 2>/dev/null; then
    fail "smoke-exit: launcher has a bash syntax error"
    return 1
  fi
  # Arg parsing + flag.
  grep -qE '\-\-smoke-exit-after-spawn' "${src}" || { fail "smoke-exit: no --smoke-exit-after-spawn arg parsing"; pass_all=0; }
  grep -qE 'SMOKE_EXIT' "${src}" || { fail "smoke-exit: no SMOKE_EXIT flag"; pass_all=0; }
  # Boot-proof sentinels (Forge contract).
  grep -qE 'AETHEL_BOOT_PROOF:SERVICES_READY' "${src}" || { fail "smoke-exit: missing SERVICES_READY sentinel"; pass_all=0; }
  grep -qE 'AETHEL_BOOT_PROOF:CLEAN_EXIT' "${src}" || { fail "smoke-exit: missing CLEAN_EXIT sentinel"; pass_all=0; }
  grep -qE 'AETHEL_BOOT_PROOF:TIMEOUT' "${src}" || { fail "smoke-exit: missing TIMEOUT sentinel"; pass_all=0; }
  # Smoke-timeout exit code 6.
  grep -qE 'exit 6' "${src}" || { fail "smoke-exit: missing 'exit 6' (smoke watchdog timeout)"; pass_all=0; }
  # Backward-compat: the default (non-smoke) path keeps the interactive trap.
  grep -qE 'trap _cleanup EXIT INT TERM' "${src}" || { fail "smoke-exit: default 'trap _cleanup EXIT INT TERM' removed (breaks interactive mode)"; pass_all=0; }

  if (( pass_all == 1 )); then
    ok "smoke-exit contract present (arg parsing, sentinels, exit-6, backward-compat)"
  fi
}

# Run all tests
test_launcher_success_path
test_voxel_build_failure
test_missing_main_entrypoint
test_missing_types_entrypoint
test_smoke_exit_contract

echo ""
echo "Walking Skeleton Launcher Tests: Passed: ${passed}  Failed: ${failures}"
if (( failures == 0 )); then
  echo "✓ test_walking_skeleton_launcher.sh passed"
  exit 0
else
  echo "✗ test_walking_skeleton_launcher.sh FAILED" >&2
  exit 1
fi
