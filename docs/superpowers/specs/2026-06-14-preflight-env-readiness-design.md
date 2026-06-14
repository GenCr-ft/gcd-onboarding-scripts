# Design: Workspace-Aware Environment Readiness Preflight

**Date:** 2026-06-14
**Repo:** `gcd-onboarding-scripts`
**Status:** Approved — pending implementation plan

---

## Problem

`gft-onboarding.sh` fails silently or mid-run when tools are missing or GitHub CLI is
unauthenticated. A newcomer following the quickstart has no upfront visibility into what
their machine needs before the script commits to any work. The existing
`check_prerequisites()` in `01_helpers.sh` only covers five tools, runs after SSoT clone
(too late for auth checks), and auto-installs without asking permission.

Additionally, the repo was private at launch — that blocker is now resolved (made public
2026-06-14). This spec addresses the remaining UX gap.

---

## Audience & Prerequisite Contract

Target users are **GenCr-ft org members** who already have a GitHub account and org
access. The welcome page (`gencr-ft.github.io`) states this prerequisite explicitly.
The preflight cannot grant org access — it can only detect its absence and provide the
join URL.

---

## Approach

**New file: `includes/07_preflight.sh`**

Sourced last in the `source` block in `gft-onboarding.sh` (after `06_workspace_files.sh`),
so it can call helpers from `00_bootstrap.sh` and `01_helpers.sh`. `run_preflight` is
called as the first action inside `main()`, before `setup_ssot_repository()`. The existing
`check_prerequisites()` call is removed — its tool checks fold into preflight.

The function signature:

```bash
run_preflight   # reads $GFT_WORKSPACE (may be empty for non-quickstart runs)
```

---

## Check Catalogue

### Universal checks (all workspaces)

| # | Check | Severity | Failure action |
|---|-------|----------|----------------|
| U-1 | Internet connectivity (`curl -s --max-time 5 https://github.com`) | Critical | Hard fail — exit immediately, no table rendered |
| U-2 | bash ≥ 4.0 | Warning | Non-blocking — macOS ships 3.x; script works but user is informed |
| U-3 | git (any version) | Critical | Prompt: "Install git? [Y/n]" |
| U-4 | curl (any version) | Critical | Prompt: "Install curl? [Y/n]" |
| U-5 | gh ≥ 2.0 (GitHub CLI) | Critical | Prompt: "Install gh? [Y/n]" |
| U-6 | python3 ≥ 3.9 | Critical | Prompt: "Install python3? [Y/n]" |
| U-7 | yq (any version) | Critical | Prompt: "Install yq? [Y/n]" |
| U-8 | unzip (any version) | Critical | Prompt: "Install unzip? [Y/n]" |
| U-9 | gh auth status | Critical | Prompt: "Run `gh auth login` now? [Y/n]" → spawn, wait |
| U-10 | git user.name set | Critical | Prompt: "Enter your name: " → `git config --global` |
| U-11 | git user.email set | Critical | Prompt: "Enter your email: " → `git config --global` |
| U-12 | GenCr-ft org membership | Critical | Print join URL, ask to confirm before continuing |
| U-13 | Disk space ≥ 2 GB in `$HOME` | Warning | Warn, ask: "Continue anyway? [Y/n]" |

### Workspace-specific checks

Loaded only when `$GFT_WORKSPACE` is set. Defined as a declarative map inside
`07_preflight.sh` — no external config file required.

| Workspace | Extra checks |
|-----------|-------------|
| `aethel` | node ≥ 20 (Critical), docker (Critical) |
| `evai-platform` | node ≥ 20 (Critical), docker (Critical), cargo/rust (Critical) |
| `agent-factory` | node ≥ 20 (Critical), docker (Critical) |
| `workspace-ops` | node ≥ 20 (Critical) |
| `studio-gencraft` | node ≥ 20 (Critical) |

Docker check verifies `docker info` succeeds (daemon running), not just binary presence.

---

## Interaction Flow

```
1. Run U-1 (connectivity) — hard exit if offline, skip rest of preflight.
2. Run all remaining checks silently → build ordered results array.
3. Render full preflight table to stdout.
4. If all Critical checks pass:
     print "✓ All checks passed. Proceeding…" → return 0
5. For each failing Critical item (in catalogue order):
     a. Installable tool (U-3–U-8, workspace tools):
          print "Missing <tool>. Install it? [Y/n]"
          Y → install_with_package_manager → recheck → update row result
          N → mark as SKIPPED (will cause exit 1 at step 7)
     b. gh auth (U-9):
          print "GitHub CLI is not authenticated. Run 'gh auth login' now? [Y/n]"
          Y → gh auth login (subprocess) → on exit, recheck gh auth status
          N → mark SKIPPED
     c. git identity (U-10, U-11):
          print "git user.<field> is not set. Enter your <field>: "
          read value → git config --global user.<field> "$value" → recheck
     d. Org membership (U-12):
          print "You must be a GenCr-ft org member."
          print "Request access: https://github.com/orgs/GenCr-ft/discussions"
          print "Press Enter once you have been added, or Ctrl-C to abort."
          read → recheck via gh api
     e. Disk space (U-13):
          print warning → "Continue anyway? [Y/n]"
          N → exit 1
6. Re-render table with final statuses.
7. If any Critical item is still failing (FAIL or SKIPPED):
     print "❌ <N> required checks failed. Please resolve them and re-run."
     exit 1
8. print "✓ Environment ready. Starting onboarding…" → return 0
```

---

## Table Format

Uses ANSI colours and plain ASCII borders (no Unicode box-drawing — WSL compatibility).

```
+-----------------------------------------------+
|  GenCr@ft Studio -- Environment Readiness     |
+---------------------+-----------+-------------+
|  Check              |  Status   |  Action     |
+---------------------+-----------+-------------+
|  Internet           |  OK       |  --         |
|  bash >= 4.0        |  WARN 3.2 |  non-block  |
|  git                |  OK       |  --         |
|  curl               |  OK       |  --         |
|  gh (GitHub CLI)    |  MISSING  |  install?   |
|  python3 >= 3.9     |  OK       |  --         |
|  yq                 |  MISSING  |  install?   |
|  unzip              |  OK       |  --         |
|  gh auth            |  UNAUTH   |  login?     |
|  git user.name      |  OK       |  --         |
|  git user.email     |  OK       |  --         |
|  org membership     |  OK       |  --         |
|  disk space         |  OK 47G   |  --         |
+---------------------+-----------+-------------+
|  workspace: aethel                            |
+---------------------+-----------+-------------+
|  node >= 20         |  OK 22.1  |  --         |
|  docker             |  MISSING  |  install?   |
+---------------------+-----------+-------------+
|  3 items need attention                       |
+-----------------------------------------------+
```

Colours: green for OK, yellow for WARN, red for MISSING/UNAUTH/FAIL, white for SKIPPED.

---

## File Structure Changes

```
includes/
  00_bootstrap.sh       (unchanged)
  01_helpers.sh         remove check_prerequisites() call site only; function body kept
                        for backwards-compat until 07_preflight.sh is proven stable,
                        then deprecated in a follow-up PR
  07_preflight.sh       NEW — all preflight logic
gft-onboarding.sh       source 07_preflight.sh; call run_preflight as first main() step;
                        remove check_prerequisites() call
tests/
  test_onboarding_logic.sh   extend with preflight scenarios (see Testing)
```

---

## Testing

Extend `tests/test_onboarding_logic.sh` with the following scenarios:

| Test | Description |
|------|-------------|
| T-1 | All checks pass → table renders, exit 0 |
| T-2 | Mixed pass/fail → table renders with correct status per row |
| T-3 | Missing tool, user answers Y → install called, row re-renders OK |
| T-4 | Missing tool, user answers N → row marked SKIPPED, exit 1 |
| T-5 | gh auth fails, user answers Y → `gh auth login` spawned |
| T-6 | Workspace-specific checks loaded for `aethel` (node, docker) |
| T-7 | Workspace-specific checks NOT loaded when `$GFT_WORKSPACE` unset |
| T-8 | Critical item still failing after interaction → exit 1 with summary |
| T-9 | Connectivity check fails → immediate exit, no table |
| T-10 | Disk space warning (non-blocking) → user can continue |

Tests use the existing fixture pattern in `tests/fixtures/`.

---

## Out of Scope

- Automatic org membership granting (requires GitHub admin action)
- Windows PowerShell equivalent (tracked separately in `onboarding-win.ps1`)
- Version pinning for workspace tools (deferred — SSoT `.tool-versions-gft` drives this
  in the install phase; preflight checks presence + minimum version floor only)
- Godot binary check (large binary, install is manual; deferred to workspace setup phase)
