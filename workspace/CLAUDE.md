# CLAUDE.md — GenCr@ft Studio Workspace

This workspace (`/home/lgan/hxgn/dev/claude/exp`) contains ~30 Git repositories belonging to **GenCr@ft Studio** (GitHub org: `GenCr-ft`). The studio is building **Aethel**, a next-generation multiplayer voxel-based RPG creative platform. Repos are cloned side-by-side; this is not a monorepo.

---

## Repo Naming Convention

| Prefix | Layer |
|--------|-------|
| `gcd-` | DevOps / developer tooling |
| `gcl-` | Shared libraries and microservices |
| `gcp-` | Product (Aethel game) |
| `gcs-` | Studio-wide standards and handbooks |
| `gct-` | Templates (repo, service, SSoT) |

---

## Key Repositories

| Repo | Role | Status |
|------|------|--------|
| `gcp-aethel-client` | Godot 4 + GDScript game client | Phase 4 complete |
| `gcp-aethel-server` | TypeScript/NestJS game server | Phase 4 complete |
| `gcp-aethel-pcg` | Rust/WASM procedural generation library | Phase 5 complete |
| `gcl-srv-authentication` | Auth microservice (RS256 JWT, RTR) | Bootstrapped + integration tests |
| `gcl-srv-persistence` | Persistence microservice (Prisma + PostgreSQL) | Bootstrapped |
| `gcl-voxel-engine` | Server-side voxel authority library | Stub |
| `gcl-ui-components` | Shared UI component library | Stub |
| `gcp-aethel-architecture` | ADRs, C4 diagrams, architectural specs | Complete through Phase 4 |
| `gcp-aethel-backlog` | Project backlog and meeting notes | Active |
| `gcp-aethel-docs-gdd` | Game Design Document | Partial |
| `gcd-ops-scripts` | Python-based SSoT linters (CI + pre-commit) | Operational |
| `gcd-onboarding-scripts` | Cross-platform dev onboarding automation | Operational |
| `gcd-shared-actions` | Reusable GitHub Actions workflows | Operational |
| `gcs-devops-standards` | Canonical DevOps/tooling SSoT | Complete |
| `gcs-engineering-handbook` | Engineering manifesto | Complete |
| `gcs-studio-handbook` | Studio-wide SSoT for all processes | Complete |
| `gcs-security-core` | Security standards | Operational |
| `gcs-plt-architecture` | Platform architecture | Operational |
| `gcs-plt-gembp` | GEM Blueprint (36/36 roles) | Complete |
| `gcs-plt-gemop` | GEM Operations (33/33 gems) | Complete |
| `gcs-plt-tools` | Platform CLI tooling (EVAI walking skeleton) | Phase 1 operational |
| `gcs-project-management` | Project management processes | Active |
| `gencraft-iac` | OpenTofu infrastructure as code | Partial |
| `gencr-ft.github.io` | Studio website | Minimal |

---

## Project Phase Status (as of 2026-05-13)

### Phase 4 — Walking Skeleton: COMPLETE ✅

All work items merged and end-to-end confirmed on WSLg/llvmpipe (2026-05-02). The vertical slice is: Auth Service login → JWT → WebSocket upgrade → flat terrain chunk → Godot render → WASD player movement.

**Launch command (WSLg):** `LIBGL_ALWAYS_SOFTWARE=1 WAYLAND_DISPLAY= godot` — click window once for keyboard focus.

| WI | Repo | Status |
|----|------|--------|
| WI-4.0 GUT test runner | `gcp-aethel-client` | ✅ merged |
| WI-4.1 ChunkData wire format | `gcp-aethel-server` | ✅ merged |
| WI-4.2 FlatTerrainGenerator | `gcp-aethel-server` | ✅ merged |
| WI-4.3 JwtValidationService | `gcp-aethel-server` | ✅ merged |
| WI-4.4 JWT gate on WebSocket upgrade | `gcp-aethel-server` | ✅ merged |
| WI-4.5 Initial chunk dispatch on connect | `gcp-aethel-server` | ✅ merged |
| WI-4.6 VoxelCore 32³ binary API | `gcp-aethel-client` | ✅ merged |
| WI-4.7 MessageDecoder | `gcp-aethel-client` | ✅ merged |
| WI-4.8 AuthClient | `gcp-aethel-client` | ✅ merged |
| WI-4.9 GameClient | `gcp-aethel-client` | ✅ merged |
| WI-4.10 PlayerController | `gcp-aethel-client` | ✅ merged |
| WI-4.11 Auth integration tests | `gcl-srv-authentication` | ✅ merged |
| WI-4.12 C4 client component diagram | `gcp-aethel-architecture` | ✅ merged |
| WI-4.13 Phase 4 connection sequence diagram | `gcp-aethel-architecture` | ✅ merged |
| WI-4.14 Mouse-look camera | `gcp-aethel-client` | ✅ merged |

### Phase 5 — PCG Integration: COMPLETE ✅

All work items merged (2026-05-10). Deliverables: Xoshiro256++ RNG parity (Rust ↔ Python), `HeightmapGenerator` with OpenSimplex fbm, WASM `generate_chunk`, Godot 4.5 migration + PCG visualizer, `pcg-cli` Heightmap command wired to real Simplex noise.

### Phase 6 — State Persistence + Multiplayer: NOT STARTED

Phase 5 is complete; Phase 6 is unblocked. Gate: GAM-SPEC-049, -066, and -085 must be approved before WI authoring — tracked in [`gcp-aethel-backlog#27`](https://github.com/GenCr-ft/gcp-aethel-backlog/issues/27) and [`gcp-aethel-backlog#34`](https://github.com/GenCr-ft/gcp-aethel-backlog/issues/34).

---

## Modus Operandi

### How we work together

**Autonomous by default.** Claude operates in Auto mode. Routine decisions (file edits, commits, branch creation, test runs, PR creation) are taken without asking. The only exceptions that require explicit confirmation: force-pushes to main, destructive operations (branch deletion, file removal), pushing to shared infra, or anything outside the current task scope.

**Test-Driven Development is non-negotiable.** Every feature WI follows the red → green cycle:
1. Create a failing test file and commit it (`test: WI-X.Y red — <description>`).
2. Implement to make tests pass and commit (`feat: WI-X.Y green — <description>`).
3. Address review comments and commit (`fix: address PR #N review comments`).

**One PR per WI.** Each work item produces exactly one PR against `main`. PRs are named `feat(scope): WI-X.Y — <description>`.

**Review comments are closed before merge.** After pushing fixes, Claude replies to each thread with a pointer to the commit that addresses it, then resolves the discussion via GraphQL if the GitHub API allows. If the reviewer hasn't resolved, Claude replies anyway to record that the fix is in.

**Parallel work via git worktrees.** When multiple WIs in the same repo must run concurrently, each agent uses `git worktree add /tmp/wi-X.Y-worktree <branch>` to avoid conflicts.

**Memory is maintained across sessions.** Claude writes project/feedback/user memories to `/home/lgan/.claude/projects/-home-lgan-hxgn-dev-claude-exp/memory/`. Always check MEMORY.md at session start for relevant context.

**Architecture-first for cross-cutting decisions.** Before implementing anything that touches the wire format, authentication, or data storage, verify the relevant ADR in `gcp-aethel-architecture/adrs/`. If no ADR exists, one must be written first.

**`./test.sh` is mandatory after source changes.** After any modification to source code in a repository, run `./test.sh` before closing the session or opening a PR. If `./test.sh` does not yet exist in the repo, this obligation still applies — use the repo's documented test command and note the absence of `test.sh` in the PR description.

**Gaps and actions become GitHub Issues immediately.** Any gap, defect, or action item identified during work — code review, audit, session analysis, or incidental discovery — must be captured as a GitHub Issue before proceeding. Nothing lives only in conversation context, plan files, or memory.

- Engineering / game bugs and improvements → `gcp-aethel-backlog` (or the affected code repo for hot fixes)
- Design / planning items → `gcs-project-management`
- Platform items → affected platform repo (`gcs-plt-tools`, `gcs-plt-architecture`, etc.)

After creating the issue, always add it to Project #16:

```bash
gh project item-add 16 --owner GenCr-ft --url <issue-url>
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Game client | Godot 4.5, GDScript |
| Backend services | TypeScript 5.3, NestJS 10, Node.js LTS |
| Backend architecture | Hexagonal Architecture (Ports & Adapters) |
| Physics | Rapier.js (WASM) in a `worker_threads` Worker |
| Transport | uWebSockets.js v20.44 |
| PCG | Rust + wasm-bindgen, Python (parity/research) |
| Data access | Prisma ORM (standard), Kysely (performance escape hatch) |
| Auth | RS256 JWT, Refresh Token Rotation (IETF BCP 212) |
| Testing (TS) | Jest — minimum 80% unit coverage |
| Testing (GDScript) | GUT v9.3.0 |
| Testing (Rust) | `cargo test` |
| Testing (Python) | pytest |
| CI/CD | GitHub Actions |
| Ops tooling | Python, Bash |
| Infrastructure | OpenTofu (IaC) |

---

## Running Tests Locally

```bash
# Run all tests (unit only, no Docker needed):
./test-all.sh --no-integration

# Run only TypeScript server repos:
./test-all.sh --server --no-integration

# Run only PCG (Rust + Python):
./test-all.sh --pcg

# Run only Godot GUT tests:
./test-all.sh --client

# Run everything including auth integration tests (needs Docker):
./test-all.sh
```

### Per-repo commands

| Repo | Command | Notes |
|------|---------|-------|
| `gcp-aethel-server` | `npm test` | Jest; no external services |
| `gcl-srv-persistence` | `npm test` | Jest; no external services (mock repo) |
| `gcl-srv-authentication` | `npm test` | Unit tests run standalone; integration tests need Postgres + Redis |
| `gcp-aethel-pcg` (Rust) | `cargo test` | No WASM build needed for unit tests |
| `gcp-aethel-pcg` (Python) | `cd pcg-godot && .pcg/bin/pytest pcg/tests/ -v` | Requires `.pcg` venv |
| `gcp-aethel-client` | `$GODOT_BIN --headless --path . -s tests/gut_runner.gd` | Needs Godot 4.5 binary |

**Godot binary:** Extract from `./Godot_v4.5-stable_linux.x86_64.zip` or set `GODOT_BIN`. The `test-all.sh` script auto-extracts if the zip is present.

**Auth integration tests** require:
```bash
# Minimal env vars:
DATABASE_URL=postgresql://user:pass@localhost:5432/auth_test
REDIS_URL=redis://localhost:6379
AUTH_RS256_PRIVATE_KEY="$(cat test-keys/private.pem)"
AUTH_RS256_PUBLIC_KEY_PEM="$(cat test-keys/public.pem)"
```

---

## Critical Technical Patterns

### uWebSockets.js async safety

`req` (HttpRequest) is stack-allocated and **invalid after the first `await`**. Always capture all header/query reads synchronously before any async work:

```typescript
async handleUpgrade(res, req, context) {
  // ALL req reads must happen HERE — synchronously
  const query = req.getQuery();
  const key = req.getHeader('sec-websocket-key');
  const protocol = req.getHeader('sec-websocket-protocol');
  const extensions = req.getHeader('sec-websocket-extensions');

  let aborted = false;
  res.onAborted(() => { aborted = true; });  // register BEFORE first await

  // ... async work ...
  const payload = await this.validator.validate(token);
  if (aborted) return;   // check AFTER every await before using res
  res.upgrade(...)
}
```

### GUT 9.3.0 testing patterns

`any_arg()` does **not** exist in GUT 9.3.0. `get_signal_parameters` causes parse errors. Use Array container lambdas instead:

```gdscript
# Capture signal arguments:
var captured: Array = []
my_object.some_signal.connect(func(a, b, c): captured.append([a, b, c]))
my_object.do_something()
assert_false(captured.is_empty())
assert_eq(captured[0], [expected_a, expected_b, expected_c])
```

### Chunk wire format

```
[0x10][cx int32 LE][cy int32 LE][cz int32 LE][98304 bytes voxel data]
```
- 32³ = 32768 voxels × 3 bytes/voxel = 98304 bytes
- Per voxel: 2 bytes `voxelType` (uint16LE) + 1 byte flags (uint8)
- `CHUNK_VOXEL_DATA_SIZE = 98304` in `message-codec.ts`

### Simulation loop — accumulator pattern

`setInterval(tick, 50)` is **forbidden** (drifts under load). Use the accumulator:

```typescript
const delay = Math.max(0, TICK_MS - accumulator);
setTimeout(runLoop, delay);  // sleep until next tick is due; no idle spin
```

### ISimulationEngine boundary

The simulation core **must not** import any Node.js platform API (`fs`, `net`, `ws`, etc.). All I/O goes through the `ISimulationEngine` interface. Enforced by ESLint `no-restricted-imports` on the `/simulation/` package.

### Rapier physics in a Worker

Physics runs in a `worker_threads` Worker. Communication uses `SharedArrayBuffer` + `Atomics` for zero-copy tick results. The main thread calls `Atomics.wait(controlView, 0, 0, 100)` to block until the worker completes the step — the 100 ms timeout prevents hangs.

---

## Git Workflow

- **Conventional Commits v1.0.0** — enforced by `commitlint`.
- **Branch naming:** `feat/`, `fix/`, `docs/`, `test/`, `chore/`, `refactor/`.
- **Every PR requires a GitHub Issue.**
- **No force-push to main** without explicit user instruction.
- **Co-author trailer** on all AI-generated commits:
  ```
  Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
  ```

---

## SSoT Document Standard

Every Markdown document must have YAML frontmatter:

```yaml
---
docId: DOMAIN-TYPE-CODE        # e.g. ENG-SPEC-008, GOV-STAN-001
title: ...
version: ...
authors: [...]
metadata:
  scope: project-aethel
  domain: engineering
  doc-type: specification      # or adr, guide, etc.
  lifecycle-stage: approved
  security-classification: l2_confidential
---
```

- `docId` format: `DOMAIN-TYPE-CODE` — validated against SSoT taxonomy.
- Filename must match `docId` (e.g. `ENG-SPEC-008.phase4-connection-sequence.md`).
- `tags:` is deprecated — use `metadata.keywords` instead.
- All relative Markdown links must resolve to existing files.
- **Language: English only.**

---

## Architecture Principles

From `gcp-aethel-architecture/ENG-SPEC-002.principles.md`:

1. **Clean Architecture** — Hexagonal (Ports & Adapters) for all backend services.
2. **Modularity** — high cohesion, low coupling.
3. **Extensibility** — designed for UGC and modding from day one.
4. **Security by Design** — not bolted on.
5. **Testability** — every component is unit-testable in isolation.
6. **Simplicity (YAGNI)** — no premature abstractions.
7. **Measure, don't guess** — profiling before optimizing.

Philosophy pillars: **Simplicity** (Unix way), **Rigor** (Dijkstra — readable, provable), **Reliability** (Hamilton — design for failure). Empty `catch` blocks are professional malpractice.

---

## Known Open Items

| Item | Repo | Tracking |
|------|------|---------|
| `gcp-aethel-docs-req` ADR-056/057 rename | `gcp-aethel-docs-req` | docId conflict with architecture ADRs — [`gcp-aethel-docs-req#44`](https://github.com/GenCr-ft/gcp-aethel-docs-req/issues/44) |
| GDD specs blocking Phase 6 | `gcp-aethel-docs-gdd` | GAM-SPEC-049, -066, -085 must be approved — [`gcp-aethel-backlog#27`](https://github.com/GenCr-ft/gcp-aethel-backlog/issues/27), [`gcp-aethel-backlog#34`](https://github.com/GenCr-ft/gcp-aethel-backlog/issues/34) |
