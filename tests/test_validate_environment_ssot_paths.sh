#!/usr/bin/env bash
set -euo pipefail

# AC-4: Skip gracefully when GFT_SSOT_PATH not set or clone unavailable
if [[ -z "${GFT_SSOT_PATH:-}" ]] || [[ ! -d "${GFT_SSOT_PATH}" ]]; then
    echo "[SKIP] WI-177 SSoT path integration tests — GFT_SSOT_PATH not set or unavailable"
    exit 0
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS_COUNT=0; FAIL_COUNT=0; SKIP_COUNT=0
pass() { echo "  [OK] $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo "  [FAIL] $1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
skip() { echo "  [SKIP] $1"; SKIP_COUNT=$((SKIP_COUNT+1)); }

# AC-1: ROLE_MATRIX_FILE resolves to an existing file and returns parseable YAML
test_role_matrix_file_resolves() {
    local yaml
    yaml=$(bash -c '
        GFT_SSOT_PATH="${1}"
        source "${2}/validate-environment.sh"
        get_yaml_from_ssot "${GFT_SSOT_PATH}/${ROLE_MATRIX_FILE}"
    ' -- "${GFT_SSOT_PATH}" "${PROJECT_ROOT}" 2>/dev/null) || {
        fail "get_yaml_from_ssot for ROLE_MATRIX_FILE failed (file not found or unparseable)"
        return
    }
    if [[ -n "${yaml}" ]]; then
        pass "ROLE_MATRIX_FILE resolves and returns non-empty YAML"
    else
        fail "ROLE_MATRIX_FILE resolved but YAML block was empty"
    fi
}

# AC-2: TOOLING_SPECS_FILE resolves when catalog present; [SKIP] if absent
test_tooling_specs_file_resolves_when_present() {
    local tooling_specs_file
    tooling_specs_file=$(bash -c '
        GFT_SSOT_PATH="${1}"
        source "${2}/validate-environment.sh"
        echo "${TOOLING_SPECS_FILE}"
    ' -- "${GFT_SSOT_PATH}" "${PROJECT_ROOT}" 2>/dev/null)

    if [[ -z "${tooling_specs_file}" ]]; then
        fail "TOOLING_SPECS_FILE constant could not be read from script"
        return
    fi

    if [[ ! -f "${GFT_SSOT_PATH}/${tooling_specs_file}" ]]; then
        skip "TOOLING_SPECS_FILE absent in this clone — AC-2 skipped"
        return 0
    fi

    local yaml
    yaml=$(bash -c '
        GFT_SSOT_PATH="${1}"
        source "${2}/validate-environment.sh"
        get_yaml_from_ssot "${GFT_SSOT_PATH}/${TOOLING_SPECS_FILE}"
    ' -- "${GFT_SSOT_PATH}" "${PROJECT_ROOT}" 2>/dev/null) || {
        fail "get_yaml_from_ssot for TOOLING_SPECS_FILE failed"
        return
    }
    if [[ -n "${yaml}" ]]; then
        pass "TOOLING_SPECS_FILE resolves and returns non-empty YAML"
    else
        fail "TOOLING_SPECS_FILE resolved but YAML block was empty"
    fi
}

# AC-3: Defensive guard logs INFO (not ERROR/FAIL) when tooling catalog absent
# Uses a minimal mock SSoT and explicitly calls get_yaml_from_ssot --optional
# to verify the --optional chain (regression guard: if --optional removed, exit 1 fires)
test_tooling_specs_absent_guard_logs_info() {
    local role_matrix_file
    role_matrix_file=$(bash -c '
        GFT_SSOT_PATH="${1}"
        source "${2}/validate-environment.sh"
        echo "${ROLE_MATRIX_FILE}"
    ' -- "${GFT_SSOT_PATH}" "${PROJECT_ROOT}" 2>/dev/null)

    local tmp_ssot
    tmp_ssot=$(mktemp -d)
    trap 'rm -rf "${tmp_ssot}"' RETURN

    mkdir -p "${tmp_ssot}/$(dirname "${role_matrix_file}")"
    printf '```yaml\nroles:\n  - name: devops-specialist\n    description: DevOps role\n    repos: []\n    tools: []\n```\n' \
        > "${tmp_ssot}/${role_matrix_file}"

    local output
    local exit_code=0
    output=$(bash -c '
        GFT_SSOT_PATH="${1}"
        source "${2}/validate-environment.sh"
        ROLE_MATRIX_YAML=$(get_yaml_from_ssot "${GFT_SSOT_PATH}/${ROLE_MATRIX_FILE}")
        TOOLING_SPECS_YAML=$(get_yaml_from_ssot "${GFT_SSOT_PATH}/${TOOLING_SPECS_FILE}" --optional)
        validate_tools_for_role "devops-specialist" 2>&1
    ' -- "${tmp_ssot}" "${PROJECT_ROOT}" 2>&1) || exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        fail "Script exited ${exit_code} — possible --optional regression in get_yaml_from_ssot call"
        return
    fi
    if echo "${output}" | grep -qi "\[ERROR\]\|\[FAIL\]"; then
        fail "defensive guard emitted ERROR/FAIL for absent tooling catalog"
        return
    fi
    if echo "${output}" | grep -q "Tool catalog unavailable\|[Ss]kipping tool validation"; then
        pass "defensive guard logs INFO when tooling catalog absent (--optional chain exercised)"
    else
        fail "expected INFO message not found; output: ${output}"
    fi
}

echo "=== test: SSoT path integration (WI-177) ==="

test_role_matrix_file_resolves
test_tooling_specs_file_resolves_when_present
test_tooling_specs_absent_guard_logs_info

echo ""
echo "--- SSoT path integration: ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${SKIP_COUNT} skipped ---"
[[ ${FAIL_COUNT} -eq 0 ]] && exit 0 || exit 1
