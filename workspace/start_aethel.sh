#!/usr/bin/env bash
# start_aethel.sh — boots all services needed to run the Aethel walking skeleton
#
# Services and ports:
#   gcl-srv-authentication  →  :3010  (avoids WSL2-mirrored Windows port :3000)
#   gcp-aethel-server HTTP  →  :3100
#   gcp-aethel-server WS    →  :3001
#   Postgres                →  :5433
#   Redis                   →  :6380
#
# Prerequisites:
#   - Docker + docker compose
#   - Node.js 20+ with npm
#   - openssl
#   - wasm-pack (for PCG WASM rebuild when src/**.rs is newer than pkg/)

set -euo pipefail

# ─── F1.5 smoke-exit contract (Forge, gcs-project-management#414 §6.2) ──────────
# --smoke-exit-after-spawn lets the E2E harness drive this launcher: after all
# services are healthy it prints AETHEL_BOOT_PROOF:SERVICES_READY, then waits;
# the harness performs the WebSocket boot proof and sends SIGTERM, which (in
# smoke mode) triggers a clean exit 0. Absent the flag, behaviour is unchanged.
SMOKE_EXIT=false
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-60}"
AUTH_PID=""
GAME_PID=""
for arg in "$@"; do
  case "$arg" in
    --smoke-exit-after-spawn) SMOKE_EXIT=true ;;
    *) echo "ERROR: Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# Resolve workspace root by probing for a known sibling repo. The script may be
# run from the workspace root directly OR from gcd-onboarding-scripts/workspace/.
# Override with WORKSPACE= if your layout differs.
_detect_workspace() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # Deployed at workspace root: siblings are the repos themselves
  if [[ -d "${script_dir}/gcl-srv-authentication" ]]; then
    echo "${script_dir}"; return
  fi
  # Canonical location: gcd-onboarding-scripts/workspace/ — two levels up
  local candidate
  candidate="$(cd "${script_dir}/../../" && pwd)"
  if [[ -d "${candidate}/gcl-srv-authentication" ]]; then
    echo "${candidate}"; return
  fi
  echo "ERROR: Cannot locate workspace root from ${script_dir}. Set WORKSPACE= explicitly." >&2
  exit 1
}
WORKSPACE="${WORKSPACE:-$(_detect_workspace)}"
AUTH_DIR="${WORKSPACE}/gcl-srv-authentication"
SERVER_DIR="${WORKSPACE}/gcp-aethel-server"
PCG_DIR="${WORKSPACE}/gcp-aethel-pcg"
KEY_DIR="${WORKSPACE}/.keys"

GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'
NC=$'\033[0m'

step() { echo -e "\n${BOLD}→ $1${NC}"; }
ok()   { echo "  ${GREEN}$1${NC}"; }
warn() { echo "  ${YELLOW}WARNING: $1${NC}"; }

# ─── Pre-flight: check required ports ─────────────────────────────────────────
check_port() {
  local port="$1" name="$2"
  local pids
  pids="$(ss -tlnp | grep ":${port}[[:space:]]" | grep -oP "pid=\K[0-9]+" | sort -u || true)"
  if [[ -n "$pids" ]]; then
    echo "  Port ${port} (${name}) held by pid(s) ${pids} — killing stale process…"
    # shellcheck disable=SC2086
    kill -9 $pids 2>/dev/null || true
    sleep 1
    if ss -tlnp | grep -q ":${port}[[:space:]]"; then
      warn "Port ${port} still in use after kill — stop it manually and re-run."
      exit 1
    fi
  fi
}

# ─── Wait for HTTP endpoint ────────────────────────────────────────────────────
wait_for_http() {
  local url="$1" label="$2"
  echo "  Waiting for ${label}…"
  for i in $(seq 1 60); do
    if curl -sf "$url" -o /dev/null 2>/dev/null; then
      ok "${label} ready."
      return 0
    fi
    sleep 1
  done
  warn "${label} did not respond within 60 s — check logs above."
  return 1
}

# ─── 1. RS256 key pair ─────────────────────────────────────────────────────────
step "RS256 key pair"
mkdir -p "$KEY_DIR"
if [[ ! -f "${KEY_DIR}/auth_private.pem" ]]; then
  openssl genrsa -out "${KEY_DIR}/auth_private.pem" 2048 2>/dev/null
  openssl rsa -in "${KEY_DIR}/auth_private.pem" -pubout -out "${KEY_DIR}/auth_public.pem" 2>/dev/null
  ok "Generated → ${KEY_DIR}/"
else
  echo "  Reusing existing keys in ${KEY_DIR}/"
fi

PRIVATE_KEY="$(cat "${KEY_DIR}/auth_private.pem")"
PUBLIC_KEY="$(cat "${KEY_DIR}/auth_public.pem")"

# ─── 2. Pre-flight port check ─────────────────────────────────────────────────
step "Pre-flight: checking required ports"
check_port 3010 "auth service"
check_port 3001 "game server WS"
check_port 3100 "game server HTTP"
ok "Ports 3010, 3001, 3100 are free."

# ─── 3. Docker: Postgres + Redis ──────────────────────────────────────────────
step "Docker: Postgres (5433) + Redis (6380)"
docker compose -f "${AUTH_DIR}/docker-compose.dev.yml" up -d

echo "  Waiting for Postgres…"
until docker compose -f "${AUTH_DIR}/docker-compose.dev.yml" exec -T postgres \
    pg_isready -U aethel -d aethel_auth -q 2>/dev/null; do
  sleep 1
done
ok "Postgres ready."

# ─── 4. Build auth service ─────────────────────────────────────────────────────
step "Build: gcl-srv-authentication"
cd "$AUTH_DIR"
[[ ! -d node_modules ]] && npm install --silent
npm run build

# ─── 5. Prisma ─────────────────────────────────────────────────────────────────
step "Prisma: generate + db push"
DATABASE_URL="postgresql://aethel:aethel@localhost:5433/aethel_auth" \
    npx prisma generate --schema=prisma/schema.prisma 2>&1 | grep -v "^$" || true
DATABASE_URL="postgresql://aethel:aethel@localhost:5433/aethel_auth" \
    npx prisma db push --schema=prisma/schema.prisma --accept-data-loss 2>&1 | grep -v "^$" || true

# ─── 6. Start auth service ─────────────────────────────────────────────────────
step "Start: gcl-srv-authentication on :3010"
PORT=3010 \
AUTH_PRIVATE_KEY_PEM="$PRIVATE_KEY" \
AUTH_PUBLIC_KEY_PEM="$PUBLIC_KEY" \
DATABASE_URL="postgresql://aethel:aethel@localhost:5433/aethel_auth" \
REDIS_URL="redis://localhost:6380" \
    node dist/main &
AUTH_PID=$!

# Fail fast if the process exits immediately (e.g. port conflict or config error)
sleep 2
if ! kill -0 "$AUTH_PID" 2>/dev/null; then
  echo ""
  warn "Auth service exited immediately — see output above."
  exit 1
fi

wait_for_http "http://localhost:3010/api" "auth service"

# ─── 7. Register test user ─────────────────────────────────────────────────────
step "Seed: register dev@aethel.local"
REGISTER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST http://localhost:3010/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"dev@aethel.local","password":"Password1!","displayName":"DevPlayer"}')

case "$REGISTER_STATUS" in
  201) ok "Test user registered." ;;
  409) echo "  Test user already exists — OK." ;;
  *)   warn "Registration returned HTTP ${REGISTER_STATUS}" ;;
esac

# ─── 8. Build + start game server ─────────────────────────────────────────────
step "Build: gcl-voxel-engine"
VOXEL_DIR="${WORKSPACE}/gcl-voxel-engine"
cd "$VOXEL_DIR"
if [[ ! -d node_modules ]]; then
  npm install --silent
fi
if ! npm run build; then
  echo "ERROR: gcl-voxel-engine package build failed" >&2
  exit 1
fi

# Parse package.json main and types entrypoints
local_voxel_json="${VOXEL_DIR}/package.json"
if [[ ! -f "$local_voxel_json" ]]; then
  echo "ERROR: gcl-voxel-engine package.json missing" >&2
  exit 1
fi
main_entry=$(node -e "console.log(require('$local_voxel_json').main || '')" 2>/dev/null || true)
types_entry=$(node -e "console.log(require('$local_voxel_json').types || '')" 2>/dev/null || true)

if [[ -z "$main_entry" || ! -f "${VOXEL_DIR}/${main_entry}" ]]; then
  echo "ERROR: gcl-voxel-engine package main entrypoint missing: ${VOXEL_DIR}/${main_entry:-}" >&2
  exit 1
fi

if [[ -z "$types_entry" || ! -f "${VOXEL_DIR}/${types_entry}" ]]; then
  echo "ERROR: gcl-voxel-engine package types entrypoint missing: ${VOXEL_DIR}/${types_entry:-}" >&2
  exit 1
fi

# ─── 8a. PCG WASM: rebuild if pkg/ is absent or any .rs source is newer ───────
step "Build: gcp-aethel-pcg WASM (conditional)"
if [[ ! -d "$PCG_DIR" ]]; then
  warn "gcp-aethel-pcg not found at ${PCG_DIR} — skipping WASM rebuild."
elif [[ ! -f "${PCG_DIR}/pkg/aethel_pcg.js" ]] || \
   find "${PCG_DIR}/src" -name "*.rs" -newer "${PCG_DIR}/pkg/aethel_pcg.js" | grep -q .; then
  if ! command -v wasm-pack &>/dev/null; then
    warn "wasm-pack not found — skipping WASM rebuild. Run: curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh"
  else
    cd "$PCG_DIR"
    wasm-pack build --target nodejs
    ok "PCG WASM rebuilt."
  fi
else
  ok "PCG WASM is up to date — skipping rebuild."
fi

step "Build: gcp-aethel-server"
cd "$SERVER_DIR"
[[ ! -d node_modules ]] && npm install --silent
rm -rf dist tsconfig.build.tsbuildinfo
npm run build

step "Start: gcp-aethel-server (HTTP :3100, WS :3001)"
# uWebSockets.js v20.44.0 ships prebuilt binaries for specific Node.js ABIs only.
# Find a Node binary whose ABI matches one of the shipped binaries.
find_uws_node() {
  local candidates=(
    "${HOME}/.nvm/versions/node/v22."*/bin/node
    "${HOME}/.nvm/versions/node/v21."*/bin/node
    "${HOME}/.nvm/versions/node/v20."*/bin/node
    "${HOME}/.nvm/versions/node/v18."*/bin/node
    "$(which node 2>/dev/null)"
    /usr/bin/node
    /usr/local/bin/node
  )
  for candidate in "${candidates[@]}"; do
    [[ -x "$candidate" ]] || continue
    local abi
    abi=$("$candidate" -e "process.stdout.write(process.versions.modules)" 2>/dev/null) || continue
    local binary="${SERVER_DIR}/node_modules/uWebSockets.js/uws_linux_x64_${abi}.node"
    if [[ -f "$binary" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

UWS_NODE=$(find_uws_node) || {
  echo ""
  warn "No Node.js binary with a compatible uWS.js ABI found."
  echo "  Available uWS.js Linux x64 binaries:"
  ls "${SERVER_DIR}/node_modules/uWebSockets.js/uws_linux_x64_"*.node 2>/dev/null \
    | sed 's/.*uws_linux_x64_//;s/\.node//' \
    | awk '{printf "    ABI %s  (Node.js %s)\n", $1, (($1==108||$1==109)?"18":($1==115?"20":($1==120?"21":($1==127?"22":"?"))))}'
  echo ""
  echo "  Current node ABI: $(node -e 'process.stdout.write(process.versions.modules)' 2>/dev/null || echo unknown)"
  echo ""
  echo "  Fix:  nvm install 20 && nvm use 20"
  exit 1
}
echo "  Using Node.js $("$UWS_NODE" --version) ($UWS_NODE)"

HTTP_PORT=3100 \
WS_PORT=3001 \
AUTH_PUBLIC_KEY_PEM="$PUBLIC_KEY" \
WORLD_SEED=42 \
TICK_RATE_HZ=20 \
MAX_PLAYERS=64 \
    "$UWS_NODE" dist/main &
GAME_PID=$!

sleep 2
if ! kill -0 "$GAME_PID" 2>/dev/null; then
  echo ""
  warn "Game server exited immediately — see output above."
  exit 1
fi

wait_for_http "http://localhost:3100/health" "game server"

# F1.5: signal the E2E harness that all services are healthy and the WebSocket
# port is accepting connections — its cue to begin the protocol-level boot proof.
if [[ "$SMOKE_EXIT" == "true" ]]; then
  echo "AETHEL_BOOT_PROOF:SERVICES_READY"
fi

# ─── Cleanup ───────────────────────────────────────────────────────────────────
_cleanup() {
  echo ""
  echo "Shutting down…"
  # SIGKILL: skip graceful shutdown so ports are released before the script exits,
  # preventing EADDRINUSE on the next run. Guard on non-empty PIDs so cleanup is
  # safe even when a failure fires the EXIT trap before a service PID is assigned.
  [[ -n "$AUTH_PID" ]] && kill -9 "$AUTH_PID" 2>/dev/null || true
  [[ -n "$GAME_PID" ]] && kill -9 "$GAME_PID" 2>/dev/null || true
  docker compose -f "${AUTH_DIR}/docker-compose.dev.yml" down 2>/dev/null || true
}
if [[ "$SMOKE_EXIT" == "true" ]]; then
  # Smoke mode: EXIT trap cleans up; a harness SIGTERM signals boot-proof reached
  # and exits 0 cleanly (distinct from an interactive Ctrl-C teardown).
  trap '_cleanup' EXIT
  trap 'echo "AETHEL_BOOT_PROOF:CLEAN_EXIT"; exit 0' TERM
else
  trap _cleanup EXIT INT TERM
fi

# ─── 9. Instructions ───────────────────────────────────────────────────────────
echo ""
echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BOLD}  Aethel — all services ready${NC}"
echo ""
echo "  Auth service    ${GREEN}http://localhost:3010${NC}"
echo "  Game server     ${GREEN}http://localhost:3100${NC}  |  ${GREEN}ws://localhost:3001${NC}"
echo ""
echo "  ${BOLD}Launch Godot client (from gcp-aethel-client/):${NC}"
echo "    godot"
echo ""
echo "  ${BOLD}Test credentials:${NC}  dev@aethel.local / Password1!"
echo "  ${BOLD}Controls:${NC}          WASD move  |  Space jump  |  Esc release mouse"
echo ""
echo "  Press ${BOLD}Ctrl+C${NC} to stop all services."
echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ "$SMOKE_EXIT" == "true" ]]; then
  # Boot-proof watchdog: the harness sends SIGTERM after asserting the boot proof,
  # interrupting this sleep so the TERM trap fires (CLEAN_EXIT / exit 0). If no
  # SIGTERM arrives in time, the harness hung — fail with a distinct exit code.
  sleep "${SMOKE_TIMEOUT_SECONDS}" || true
  echo "AETHEL_BOOT_PROOF:TIMEOUT" >&2
  exit 6
else
  wait
fi
