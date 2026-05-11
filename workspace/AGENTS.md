# AGENTS.md — GenCr@ft Studio Workspace

> **Read this file first.** This is the authoritative onboarding guide for any contributor — human or AI — starting work in this workspace. It supersedes `AGENT.md`. Read `CLAUDE.md` alongside it for stack specifics, test commands, and critical code patterns.

---

## 1. What We Are Building

**GenCr@ft** is an independent game studio building **Aethel**: a next-generation multiplayer voxel-based RPG creative platform — think Minecraft meets Roblox with deep RPG progression and user-generated content, moddable from day one.

- **Studio:** GenCr@ft (GitHub org: `GenCr-ft`)
- **Workspace:** 33 Git repos, side-by-side at `/home/lgan/hxgn/dev/claude/exp` (not a monorepo)
- **Current phase:** Phase 5 — PCG Integration (Phase 4 complete; Phase 6 not started)

---

## 2. Repo Index

### Product — Aethel Game (`gcp-`)

| Repo | Stack | Purpose | AGENTS.md |
|------|-------|---------|-----------|
| `gcp-aethel-server` | TypeScript/NestJS | Authoritative game server, simulation loop, WebSocket | [→](gcp-aethel-server/AGENTS.md) |
| `gcp-aethel-client` | Godot 4.5/GDScript | Game client, voxel rendering, player controller | [→](gcp-aethel-client/AGENTS.md) |
| `gcp-aethel-pcg` | Rust+WASM / Python | Procedural content generation library | [→](gcp-aethel-pcg/AGENTS.md) |
| `gcp-aethel-architecture` | Markdown/Mermaid | ADRs, C4 diagrams, NFRs, architectural principles | [→](gcp-aethel-architecture/AGENTS.md) |
| `gcp-aethel-backlog` | Markdown | Engineering backlog (ENG-BACK-NNN), meeting notes, remediation plan | [→](gcp-aethel-backlog/AGENTS.md) |
| `gcp-aethel-docs-gdd` | Markdown | Game Design Document (GAM-SPEC-NNN) | [→](gcp-aethel-docs-gdd/AGENTS.md) |
| `gcp-aethel-docs-lw` | Markdown | Lore & World-Building "Truth Bible" | [→](gcp-aethel-docs-lw/AGENTS.md) |
| `gcp-aethel-docs-req` | Markdown | Requirements SSoT (ENG-REQ-NNN) | [→](gcp-aethel-docs-req/AGENTS.md) |
| `gcp-aethel-docs-external` | Markdown | External-facing player/modder documentation (stub) | [→](gcp-aethel-docs-external/AGENTS.md) |

### Shared Libraries & Microservices (`gcl-`)

| Repo | Stack | Purpose | AGENTS.md |
|------|-------|---------|-----------|
| `gcl-srv-authentication` | TypeScript/NestJS/Prisma | Auth microservice (RS256 JWT, RTR, JWKS) | [→](gcl-srv-authentication/AGENTS.md) |
| `gcl-srv-persistence` | TypeScript/NestJS/Prisma | Persistence microservice (Tier 1 PostgreSQL) | [→](gcl-srv-persistence/AGENTS.md) |
| `gcl-voxel-engine` | TypeScript (stub) | Server-side voxel authority library (stub) | [→](gcl-voxel-engine/AGENTS.md) |
| `gcl-ui-components` | TBD (stub) | Shared UI component library (stub — framework decision pending) | [→](gcl-ui-components/AGENTS.md) |

### DevOps / Tooling (`gcd-`)

| Repo | Stack | Purpose | AGENTS.md |
|------|-------|---------|-----------|
| `gcd-ops-scripts` | Python | SSoT compliance linters (pre-commit hooks + CI) | [→](gcd-ops-scripts/AGENTS.md) |
| `gcd-shared-actions` | GitHub Actions YAML | Reusable CI/CD workflows for entire studio | [→](gcd-shared-actions/AGENTS.md) |
| `gcd-onboarding-scripts` | Bash / PowerShell | Cross-platform developer onboarding orchestration | [→](gcd-onboarding-scripts/AGENTS.md) |
| `gcd-backup-utilities` | TBD (stub) | Backup utilities (stub — scope pending) | [→](gcd-backup-utilities/AGENTS.md) |

### Studio-Wide Standards (`gcs-`)

| Repo | Stack | Purpose | AGENTS.md |
|------|-------|---------|-----------|
| `gcs-devops-standards` | Markdown | DevOps governance SSoT ("The Law") | [→](gcs-devops-standards/AGENTS.md) |
| `gcs-engineering-handbook` | Markdown | Engineering manifesto and technical guides | [→](gcs-engineering-handbook/AGENTS.md) |
| `gcs-studio-handbook` | Markdown | Studio-wide operational SSoT and knowledge hub | [→](gcs-studio-handbook/AGENTS.md) |
| `gcs-security-core` | Markdown | SSDLC mandate, threat model templates, legal IR procedure | [→](gcs-security-core/AGENTS.md) |
| `gcs-studio-legal` | Markdown | Legal documents (ALL DRAFT — not legally binding) | [→](gcs-studio-legal/AGENTS.md) |
| `gcs-plt-architecture` | Markdown | Platform architecture ADRs, TDDs, C4 diagrams | [→](gcs-plt-architecture/AGENTS.md) |
| `gcs-plt-gembp` | YAML | Gem design specifications (36 AI agent blueprints) | [→](gcs-plt-gembp/AGENTS.md) |
| `gcs-plt-gemop` | Markdown | Gem operations: system prompts, 9 skills, communication protocols | [→](gcs-plt-gemop/AGENTS.md) |
| `gcs-plt-tools` | Python/Docker | EvolvAI DevSphere platform CLI + microservices | [→](gcs-plt-tools/AGENTS.md) |
| `gcs-plt-docs-req` | Markdown | Platform requirements (stub — KG not yet assigned) | [→](gcs-plt-docs-req/AGENTS.md) |
| `gcs-project-management` | Markdown/Python | Project tracker (PRO-REPO-002, 106 PROJ-* tasks) | [→](gcs-project-management/AGENTS.md) |

### Templates (`gct-`)

| Repo | Stack | Purpose | AGENTS.md |
|------|-------|---------|-----------|
| `gct-repo-template-standard` | Node/Markdown | Standard repo scaffolding template | [→](gct-repo-template-standard/AGENTS.md) |
| `gct-service-template-py` | Python/Poetry | Python microservice bootstrap template | [→](gct-service-template-py/AGENTS.md) |
| `gct-ssot-templates` | Markdown | 42 document, issue, and PR templates | [→](gct-ssot-templates/AGENTS.md) |

### Infrastructure & Web

| Repo | Stack | Purpose | AGENTS.md |
|------|-------|---------|-----------|
| `gencraft-iac` | OpenTofu / YAML | Infrastructure as Code (GitHub org + AWS/GCP environments) | [→](gencraft-iac/AGENTS.md) |
| `gencr-ft.github.io` | HTML/Jekyll | Public studio website (GitHub Pages) | [→](gencr-ft.github.io/AGENTS.md) |

---

## 3. Skipped / Non-Repo Directories

| Directory | Reason |
|-----------|--------|
| `.claude/` | Claude Code workspace config — not a repo |
| `.github/` | GitHub community health files mirror (local copy) |
| `.github-private/` | Private GitHub org config — not a repo |
| `.keys/` | Local key files — not a repo |
| `.planning/` | Local planning notes and planning agent session files |
| `senior expertise/` | Local reference material — not a repo |
| `Godot_v4.5-stable_linux.x86_64` | Extracted Godot binary — not a repo |
| `Godot_v4.2-stable_linux.x86_64` | Legacy extracted Godot binary — not a repo |

---

## 4. Shared Tooling & Conventions

### Pre-commit Hooks (all repos)

All repos use the studio-canonical `.pre-commit-config.yaml` (v1.0) from `gcs-devops-standards`. It runs:
- `detect-secrets` — blocks committed secrets
- `markdownlint` — Markdown formatting (v1.3 Approved config)
- `yamllint` — YAML validation (line-length: 120)
- `metadata-linter`, `naming-linter`, `link-linter` — SSoT compliance (from `gcd-ops-scripts` v4.0.0)
- Language-specific: `ruff` (Python), `eslint` (TypeScript), `shellcheck` (Bash), `cargo fmt`/`clippy` (Rust)
- `commitlint` — Conventional Commits v1.0.0

```bash
# Install hooks in any repo:
pip install pre-commit
pre-commit install

# Run all hooks manually:
pre-commit run --all-files
```

### Conventional Commits (all repos)

Types enforced by `commitlint.config.js`: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Header max length: 100 characters.

AI-generated commits must include:
```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

### SSoT Document Standard (all Markdown repos)

Every Markdown document must have YAML frontmatter:

```yaml
---
docId: DOMAIN-TYPE-CODE        # e.g. ENG-SPEC-008, GAM-SPEC-081
title: ...
version: ...
authors: [...]
creation_date: 'YYYY-MM-DD'
last_updated_date: 'YYYY-MM-DD'
language: en
summary: ...
metadata:
  lifecycle-stage: draft        # draft | approved | superseded
  scope: project-aethel         # or studio, studio-wide
  domain: engineering           # or game-design, production-management
  doc-type: specification       # adr | guide | backlog | index | readme | etc.
  security-classification: l2_confidential
  keywords: [...]
---
```

Rules:
- `docId` format `DOMAIN-TYPE-CODE` is non-negotiable.
- Filename must contain the docId.
- `tags:` is deprecated — use `metadata.keywords`.
- `language: en` — English only across the workspace.
- All relative Markdown links must resolve to existing files.

### CI/CD (all repos)

All repos call the reusable SSoT linter from `gcd-shared-actions`:
```yaml
uses: GenCr-ft/gcd-shared-actions/.github/workflows/reusable-ssot-linter.yml@v1.2.5
with:
  governance-version: "v1.4.0"
  tooling-version: "v4.1.2"
```

Code repos (TypeScript, Python) additionally run lint, test, and build jobs in their own `ci.yml`.

---

## 5. Cross-Repo Workflows

### Per-Repo Entry Points (ENG-PLAN-TESTSH — complete)

Every active repo now exposes two standard scripts at its root:

| Script | Purpose |
|--------|---------|
| `./onboard.sh` | Idempotent first-time setup (install deps, check toolchain) |
| `./test.sh` | Run unit tests (no external services by default) |
| `./test.sh --coverage` | Unit tests with coverage report |
| `./test.sh --integration` | Full suite incl. integration tests (needs Docker/env vars) |

### Full Test Suite

```bash
# All tests (unit only, no Docker):
./test-all.sh --no-integration

# TypeScript server repos only:
./test-all.sh --server --no-integration

# PCG (Rust + Python) only:
./test-all.sh --pcg

# Godot GUT tests only:
./test-all.sh --client

# Everything including auth integration tests (needs Docker):
./test-all.sh
```

### Walking Skeleton (Phase 4 — verification)

```bash
# Terminal 1: start auth service
cd gcl-srv-authentication && npm install && npm run start:dev

# Terminal 2: start game server (needs auth running)
cd gcp-aethel-server && npm install && npm run start:dev

# Terminal 3: launch Godot client
LIBGL_ALWAYS_SOFTWARE=1 WAYLAND_DISPLAY= ./Godot_v4.5-stable_linux.x86_64 --path gcp-aethel-client/.
# Click window once for keyboard focus → WASD to move
```

### PCG Development Workflow (Phase 5)

```bash
# 1. Run Rust tests:
cd gcp-aethel-pcg && cargo test

# 2. Run Python parity tests:
cd gcp-aethel-pcg/pcg-godot && .pcg/bin/pytest tests/ -v

# 3. Run bash parity test (Rust ↔ Python bit-identical):
bash tests/test_parity_py_rs.sh

# 4. Build WASM (when ready for server integration):
wasm-pack build --target nodejs --out-dir pkg/
```

### SSoT Compliance Check

```bash
# In any repo:
pre-commit run metadata-linter naming-linter link-linter --all-files
```

### Tracker Validation

```bash
python3 gcs-project-management/scripts/validate_tracker_rows.py
```

---

## 6. Inter-Repo Dependency Map

```
                         ┌─────────────────────┐
                         │  gcp-aethel-client  │  Godot 4.5
                         │  (GUT tests)        │
                         └──────────┬──────────┘
                                    │ WebSocket (ENG-ADR-059)
                         ┌──────────▼──────────┐
                         │  gcp-aethel-server  │  TypeScript/NestJS
                         │  (Jest tests)       │
                         └──┬──────┬──────┬───┘
                            │      │      │
                   JWT      │      │      │  IChunkGenerator
              validation    │      │      │  (Phase 5)
                            ▼      ▼      ▼
             ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
             │ gcl-srv-auth │  │ gcl-srv-pers │  │ gcp-aethel-  │
             │ (Postgres+   │  │ (Postgres    │  │ pcg          │
             │  Redis)      │  │  Prisma)     │  │ (Rust/WASM)  │
             └──────────────┘  └──────────────┘  └──────────────┘

  Governance chain (all repos):
  gcs-devops-standards → gcd-ops-scripts → gcd-shared-actions → all repos (via pre-commit + CI)

  ADR authority:
  gcp-aethel-architecture (game) + gcs-plt-architecture (platform) → all implementation repos

  Project tracking:
  gcs-project-management (PROJ-NNN) ←→ gcp-aethel-backlog (ENG-BACK-NNN) → GitHub Project #16
```

### Build Order (for fresh deployment)

1. `gcl-srv-authentication` — root of trust; must be running for JWT validation
2. `gcl-srv-persistence` — player data store; needed by game server
3. `gcp-aethel-pcg` — WASM build → npm publish (once Phase 5 complete)
4. `gcp-aethel-server` — consumes auth, persistence, PCG; runs simulation
5. `gcp-aethel-client` — connects to server

---

## 7. Getting Started From Scratch

```bash
# 1. Clone all repos (or use gcd-onboarding-scripts):
cd /home/lgan/hxgn/dev/claude/exp

# 2. Install pre-commit:
pip install pre-commit

# 3. Install Node.js 20 LTS:
nvm install 20 && nvm use 20

# 4. Install Rust:
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 5. Install wasm-pack:
cargo install wasm-pack

# 6. Install Python 3.11+:
# (use pyenv or system package manager)

# 7. Extract Godot binary:
unzip Godot_v4.5-stable_linux.x86_64.zip
chmod +x Godot_v4.5-stable_linux.x86_64
export GODOT_BIN="$(pwd)/Godot_v4.5-stable_linux.x86_64"

# 8. Install dependencies in each active repo (idempotent):
for repo in gcl-srv-authentication gcl-srv-persistence gcp-aethel-server \
            gcp-aethel-client gcp-aethel-pcg gcd-ops-scripts; do
  echo "=== $repo ==="
  (cd "$repo" && ./onboard.sh)
done

# 9. Run unit tests:
./test-all.sh --no-integration

# — or per-repo: —
# cd <repo> && ./test.sh

# 10. Verify walking skeleton:
# (see §5 Cross-Repo Workflows above)
```

---

## 8. Planning Model — Mandatory

This studio uses the **plan-with-files** methodology. Every contributor must follow this model.

### The Three Layers

| Layer | Medium | What it contains | When to use |
|-------|--------|-----------------|-------------|
| **1 — Plan** | Files in repos | Analysis, design specs, ADRs, backlog files, wave execution plans | Always the primary source of truth |
| **2 — Execute** | GitHub Issues | Active work items — one issue per deliverable, created when the wave activates | Only when work becomes active |
| **3 — View** | GitHub Project #16 | Cross-repo Kanban; all active issues from both trackers | Sprint review, status check |

### Rules

1. **Never implement without a linked source.** Every GitHub Issue must reference an ENG-BACK item, a PROJ-* task, or a GDD spec.
2. **Issues are created wave-by-wave.** Do not batch-create future issues. Only create issues for the current active wave.
3. **Every issue goes on Project #16:** `gh project item-add 16 --owner GenCr-ft --url <issue-url>`
4. **Files win over issues.** If a file and an issue conflict, trust the file.
5. **Close issues with a reference:** `Resolved by PR GenCr-ft/<repo>#<n>`

### Single Source of Truth

| Information type | Authoritative location |
|-----------------|----------------------|
| Game design specs | `gcp-aethel-docs-gdd/` — `GAM-SPEC-NNN.*` |
| Engineering decisions | `gcp-aethel-architecture/adrs/` — `ENG-ADR-NNN.*` |
| Phase design task tracking | `gcs-project-management/PRO-REPO-002.master-action-tracker.md` |
| Per-repo improvement backlog | `gcp-aethel-backlog/meeting-notes/senior-expertise-audit/ENG-BACK-NNN.*` |
| Sequenced wave execution plan | `gcp-aethel-backlog/meeting-notes/senior-expertise-audit/REMEDIATION-PLAN.md` |
| Active work items | GitHub Issues + Project #16 |
| Studio-wide operational standards | `gcs-studio-handbook/` |
| Engineering standards | `gcs-engineering-handbook/` |
| AI Gem profiles | `gcs-plt-gemop/` |
| AI Gem blueprints | `gcs-plt-gembp/` |

### Two-Tracker Model

| Tracker | Repo | Scope | Next ID |
|---------|------|-------|---------|
| Design roadmap | `gcs-project-management` | PROJ-* design tasks (106 tasks) | `PROJ-107` |
| Engineering backlog | `gcp-aethel-backlog` | ENG-BACK-NNN.* (252 items, 33 repos) | per-file |
| Cross-org view | GitHub Project #16 | All active issues | `https://github.com/orgs/GenCr-ft/projects/16` |

---

## 9. How to Work — Non-Negotiable Rules

### Test-Driven Development

Every feature follows the red → green cycle:
1. Create failing test, commit: `test: WI-X.Y red — <description>`
2. Implement to pass tests, commit: `feat: WI-X.Y green — <description>`
3. Address review comments, commit: `fix: address PR #N review comments`

### Git Workflow

- **Conventional Commits v1.0.0** — enforced by `commitlint`.
- **Branch naming:** `feat/`, `fix/`, `docs/`, `test/`, `chore/`, `refactor/`, `ci/`
- **One PR per work item.** PR title: `feat(scope): WI-X.Y — <description>`
- **Every PR requires a GitHub Issue.**
- **No force-push to main** without explicit user instruction.
- **Co-author trailer on AI commits:** `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`

### Issue Lifecycle

1. Create issue in the appropriate repo.
2. `gh project item-add 16 --owner GenCr-ft --url <issue-url>`
3. Create branch, reference issue in PR body.
4. Close with: `Resolved by PR GenCr-ft/<repo>#<n>`

---

## 10. Critical Technical Patterns

### uWebSockets.js — async safety (ENG-ADR-063)

`req` (HttpRequest) is stack-allocated and **invalid after the first `await`**:

```typescript
async handleUpgrade(res, req, context) {
  const query = req.getQuery();           // ALL req reads HERE — synchronously
  const key = req.getHeader('sec-websocket-key');
  const protocol = req.getHeader('sec-websocket-protocol');
  const extensions = req.getHeader('sec-websocket-extensions');
  let aborted = false;
  res.onAborted(() => { aborted = true; }); // register BEFORE first await
  const payload = await this.validator.validate(token);
  if (aborted) return;                      // check AFTER every await
  res.upgrade(...)
}
```

### Simulation Loop — Accumulator Pattern

`setInterval(tick, 50)` is **forbidden** (drifts under load):

```typescript
const delay = Math.max(0, TICK_MS - accumulator);
setTimeout(runLoop, delay);   // sleep until next tick is due
```

### Chunk Wire Format

```
[0x10][cx int32 LE][cy int32 LE][cz int32 LE][98304 bytes voxel data]
```
- 32³ = 32768 voxels × 3 bytes/voxel = 98304 bytes
- Per voxel: 2 bytes `voxelType` (uint16LE) + 1 byte flags (uint8)
- `CHUNK_VOXEL_DATA_SIZE = 98304` in `message-codec.ts`

### Voxel Index Convention (ENG-ADR-065)

```
index = (y * 32 * 32 + z * 32 + x) * 3   ← y-major, z before x
```

> ⚠️ Known bug: ENG-BACK-016-002 (`gcp-aethel-pcg`) and ENG-BACK-017-001 (`gcp-aethel-server`) have x/z transposed. Fix both together in Wave 1 Stream 1.

### GUT 9.3.0 Signal Testing

`any_arg()` does not exist. Use lambda capture:

```gdscript
var captured: Array = []
my_object.some_signal.connect(func(a, b, c): captured.append([a, b, c]))
my_object.do_something()
assert_false(captured.is_empty())
assert_eq(captured[0], [expected_a, expected_b, expected_c])
```

### ISimulationEngine Boundary

`src/simulation/` in `gcp-aethel-server` must **never** import `fs`, `net`, `ws`, or any Node.js platform API. Enforced by ESLint `no-restricted-imports`.

### Rapier Physics Worker (ENG-ADR-062)

Physics runs in a `worker_threads` Worker. Main thread calls `Atomics.wait(controlView, 0, 0, 100)` — 100ms timeout prevents hangs.

---

## 11. Current Phase Status

| Phase | Status | Blocking item |
|-------|--------|--------------|
| **Phase 4 — Walking Skeleton** | ✅ Complete | — |
| **Phase 5 — PCG Integration** | 🔄 In Progress | PR #42 (Simplex noise) → WASM build → server integration |
| **Phase 6 — State Persistence + Multiplayer** | ⏳ Not Started | Requires Phase 5 complete |

### Active Remediation: Wave 1

| Stream | Scope | Status |
|--------|-------|--------|
| Stream 1 — Security & Code Bugs | `gcl-srv-persistence`, `gcl-srv-authentication`, `gcp-aethel-server`, `gcp-aethel-pcg`, `gcp-aethel-client`, `gcs-plt-tools` | Not started |
| Stream 2 — Infrastructure & DevOps | `gencraft-iac`, `gcd-ops-scripts`, `gcd-shared-actions`, `gcd-onboarding-scripts` | Not started |
| Stream 3 — Architecture & ADRs | `gcp-aethel-architecture` | Partial (1/5) |
| Stream 4 — GDD Design Contracts | `gcp-aethel-docs-gdd` | Partial (4/8) |
| Stream 5 — Governance & Templates | `gcs-studio-handbook`, `gct-ssot-templates`, others | Partial (1/20) |
| Stream 6 — SSoT Compliance Sweep | 15 repos | Not started |

Full detail: `gcp-aethel-backlog/meeting-notes/senior-expertise-audit/REMEDIATION-PLAN.md`

---

## 12. Known Critical Issues (pre-Wave 1)

| Issue | Ref | Repo | Impact |
|-------|-----|------|--------|
| Voxel index transposition (x/z swapped) | ENG-BACK-016-002 | `gcp-aethel-pcg` | Scrambled terrain |
| Same transposition in server | ENG-BACK-017-001 | `gcp-aethel-server` | Same — fix both together |
| JWT auth guard missing on persistence endpoints | ENG-BACK-006-001 | `gcl-srv-persistence` | Unauthenticated data access |
| `setInterval` drift in SimulationRunner | ENG-BACK-017-002 | `gcp-aethel-server` | Tick overlap under load |
| `ValidationPipe` missing in auth bootstrap | ENG-BACK-005-001 | `gcl-srv-authentication` | `class-validator` silently bypassed |
| Stray `bash` binary in PCG repo root | ENG-BACK-016-001 | `gcp-aethel-pcg` | Security risk |

---

## 13. Session Start Checklist

Run at the start of every work session before touching any code:

1. Read this file (`AGENTS.md`)
2. Read `CLAUDE.md` for stack, test commands, and critical code patterns
3. Open `gcp-aethel-backlog/meeting-notes/senior-expertise-audit/REMEDIATION-PLAN.md` → current active wave
4. Open Project #16 (`https://github.com/orgs/GenCr-ft/projects/16`) → open issues
5. Open `gcs-project-management/PRO-REPO-002.master-action-tracker.md` → IN PROGRESS design tasks
6. Pick the highest-priority open issue and open a branch

**Do not start implementation based on memory or prior context alone. Always verify current state from the files.**
