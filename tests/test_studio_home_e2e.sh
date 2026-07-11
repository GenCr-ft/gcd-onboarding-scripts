#!/usr/bin/env bash
# ==============================================================================
# WI-384b E2E: drive the REAL onboarding main() end-to-end (transport/network
# stubbed) in an isolated HOME, for the two scenarios the migration must handle:
#   A. Fresh install         — shared tooling lands in studio_home() (~/.gft-studio),
#                              gft is configured, GFT_SSOT_GEMOP_PATH is written,
#                              nothing is cloned into GFT_PROJECTS_HOME, no legacy
#                              warning.
#   B. Returning user        — legacy ~/gft_studio exists and the profile carries an
#                              OLD GFT_SSOT_GEMOP_PATH; the run warns once about the
#                              legacy layout and converges GFT_SSOT_GEMOP_PATH to
#                              studio_home()/gcs-plt-gemop.
# This exercises the actual script entrypoint (set -e, include sourcing, main
# orchestration, bootstrap_shared_tooling, configure_gft_cli), which unit tests
# that source individual functions cannot — the class of gap that shipped five
# prior real-run onboarding bugs (see ENG-ADR-088 / WI-384b).
# ==============================================================================
# Stage stubs (install_tools_for_role, gh(), etc.) are invoked indirectly by
# onboarding_main; shellcheck cannot see the indirection (file-wide directive).
# shellcheck disable=SC2317
set -uo pipefail
TEST_SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT=$(cd "$TEST_SCRIPT_PATH/.." && pwd)
export TEST_ENV=true SCRIPT_DIR="$PROJECT_ROOT"
# shellcheck disable=SC1091
source "${PROJECT_ROOT}/gft-onboarding.sh"
# Re-expose main() under a distinct name (the real script guards direct exec).
eval "$(declare -f main | sed '1s/main/onboarding_main/')"

failed=0
fail() { echo "[FAIL] $1"; ((failed++)); }

# --- Mock SSoT (role matrix + standards), mirroring the first-run harness. -----
seed_mock_ssot() {
    [[ "$GFT_SSOT_PATH" != "$PROJECT_ROOT"* ]] || { fail "mock SSoT must not write into the repo"; return; }
    rm -rf "$GFT_SSOT_PATH"
    mkdir -p "$GFT_SSOT_PATH/tooling" "$GFT_SSOT_PATH/tooling/ssot" "$GFT_SSOT_PATH/foundations/governance"
    cp "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/tooling/ENG-STAN-002.environment-variable-standard.md" "$GFT_SSOT_PATH/tooling/"
    cp "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/tooling/ENG-STAN-003.vs-code-extension-recommendations.md" "$GFT_SSOT_PATH/tooling/"
    cp "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md" \
        "$GFT_SSOT_PATH/foundations/governance/GOV-GUIDE-010.role-tooling--resource-matrix.md"
    printf 'nodejs lts-gallium\npython 3.11.5\nopentofu 1.6.0\n' > "$GFT_SSOT_PATH/tooling/ssot/.tool-versions-gft"
    printf 'public.ecr.aws/docker/library/node:20\n' > "$GFT_SSOT_PATH/tooling/ssot/.docker-images-gft"
}

# gh stub: no network. `repo clone` makes the target dir; for gcs-plt-tools it also
# drops a mock onboard.sh so the delegated gft install produces ~/.local/bin/gft.
make_gh_stub() {
cat <<'GHEOF'
gh() {
    if [[ "${1:-}" == "ssh-key" || ( "${1:-}" == "repo" && "${2:-}" == "view" ) ]]; then echo 1; return 0; fi
    if [[ "${1:-}" == "repo" && "${2:-}" == "clone" ]]; then
        mkdir -p "$4"
        if [[ "$3" == "GenCr-ft/gcs-plt-tools" ]]; then
            cat > "$4/onboard.sh" <<'MOCK'
#!/usr/bin/env bash
mkdir -p "$HOME/.local/bin"
printf '#!/usr/bin/env bash\n[[ "${1:-}" == "version" ]] && echo "e2e-gft" && exit 0\n' > "$HOME/.local/bin/gft"
chmod +x "$HOME/.local/bin/gft"
MOCK
            chmod +x "$4/onboard.sh"
        fi
        return 0
    fi
    return 0
}
GHEOF
}

run_onboarding() {  # $1=home $2=workspace $3=out ; runs the real main in a subshell
    local home="$1" ws="$2" out="$3"
    (
        export HOME="$home" GFT_PROJECTS_HOME="$ws"
        export GFT_NON_INTERACTIVE=true GFT_ROLE=devops-specialist
        export PATH="/usr/bin:/bin"
        git config --global user.name "E2E" 2>/dev/null || true
        git config --global user.email "e2e@example.com" 2>/dev/null || true
        eval "$(make_gh_stub)"
        # Stub the heavy/irrelevant stages (same set the first-run smoke stubs),
        # leaving bootstrap_shared_tooling + configure_gft_cli to run for real.
        install_tools_for_role() { :; }
        setup_ssot_repository()   { :; }
        install_gft_ops_scripts() { :; }
        performance_and_caching() { :; }
        final_validation()        { :; }
        seed_mock_ssot
        load_ssot_configuration() { ROLE_MATRIX_YAML=$(sed -n '/```yaml/,/```/p' "${TEST_SCRIPT_PATH}/fixtures/mock_ssot/mock-role-tooling-matrix.md" | sed '1d;$d'); export ROLE_MATRIX_YAML; }
        onboarding_main
    ) >"$out" 2>&1
}

# ============================== Scenario A: fresh =============================
A_home=$(mktemp -d); A_ws=$(mktemp -d); A_out=$(mktemp)
run_onboarding "$A_home" "$A_ws" "$A_out"; a_rc=$?

[[ $a_rc -eq 0 ]] || { fail "fresh: onboarding main exited $a_rc"; sed -n '$p;1,3p' "$A_out"; }
for r in gcs-plt-tools gcs-plt-gemop gcs-core-governance; do
    [[ -d "$A_home/.gft-studio/$r" ]] || fail "fresh: shared repo '$r' not in studio_home (~/.gft-studio)"
    [[ ! -d "$A_ws/$r" ]] || fail "fresh: shared repo '$r' must NOT be cloned into GFT_PROJECTS_HOME"
done
[[ -x "$A_home/.local/bin/gft" ]] || fail "fresh: delegated gft wrapper not installed"
grep -q "export GFT_PLT_ROOT=$A_home/.gft-studio/gcs-plt-tools" "$A_home/.bashrc" 2>/dev/null \
    || fail "fresh: GFT_PLT_ROOT not written to studio_home in profile"
grep -q "export GFT_SSOT_GEMOP_PATH=$A_home/.gft-studio/gcs-plt-gemop" "$A_home/.bashrc" 2>/dev/null \
    || fail "fresh: GFT_SSOT_GEMOP_PATH not written to studio_home in profile"
grep -q "Legacy workspace" "$A_out" && fail "fresh: legacy warning emitted with no ~/gft_studio present"

# ====================== Scenario B: returning user ===========================
B_home=$(mktemp -d); B_ws=$(mktemp -d); B_out=$(mktemp)
mkdir -p "$B_home/gft_studio"   # legacy layout present
# Pre-seed a profile carrying the OLD GFT_SSOT_GEMOP_PATH (points into ~/gft_studio).
cat > "$B_home/.bashrc" <<EOF
# GENCRAFT ENVIRONMENT - START
export GFT_SSOT_GEMOP_PATH="$B_home/gft_studio/gcs-plt-gemop"
# GENCRAFT ENVIRONMENT - END
EOF
run_onboarding "$B_home" "$B_ws" "$B_out"; b_rc=$?

[[ $b_rc -eq 0 ]] || { fail "returning: onboarding main exited $b_rc"; sed -n '$p' "$B_out"; }
grep -q "Legacy workspace" "$B_out" || fail "returning: legacy ~/gft_studio warning not emitted"
[[ "$(grep -c 'Legacy workspace' "$B_out")" -eq 1 ]] || fail "returning: legacy warning emitted more than once"
grep -q "export GFT_SSOT_GEMOP_PATH=$B_home/.gft-studio/gcs-plt-gemop" "$B_home/.bashrc" \
    || fail "returning: GFT_SSOT_GEMOP_PATH not converged to studio_home"
grep -q "gft_studio/gcs-plt-gemop\"" "$B_home/.bashrc" \
    && fail "returning: stale ~/gft_studio GFT_SSOT_GEMOP_PATH still present after convergence"

rm -rf "$A_home" "$A_ws" "$A_out" "$B_home" "$B_ws" "$B_out"

if [[ $failed -ne 0 ]]; then echo "🔴 test_studio_home_e2e: $failed failed."; exit 1; fi
echo "✓ test_studio_home_e2e: fresh + returning-user scenarios passed."
