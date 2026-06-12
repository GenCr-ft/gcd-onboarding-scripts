---
docId: GOV-PLAN-113
issue-id: GenCr-ft/gcd-onboarding-scripts#113
github-issue: https://github.com/GenCr-ft/gcd-onboarding-scripts/issues/113
workspace: workspace-ops
status: in_progress
---
# [CODE] Issue 113 Onboarding First-Run Repair

## Goal
Make the documented `gcd-onboarding-scripts` first-run path executable and truthful for a new developer on a clean workstation.

## Current Phase
Phase 6

## Phases

### Phase 1: Requirements & Discovery
- [x] Read issue #113 objective, scope, evidence, and acceptance criteria.
- [x] Read repo `AGENTS.md` and workspace-ops `STATUS.md`.
- [x] Confirm no existing `.planning/` directory for issue #113.
- [x] Document sandbox findings in `findings.md`.
- **Status:** complete

### Phase 2: Planning & Traceability
- [x] Define exact implementation approach.
- [x] Post implementation plan to issue #113.
- [x] Create branch `fix/issue-113-onboarding-first-run`.
- **Status:** complete

### Phase 3: Red Tests
- [x] Add failing tests for role stdout purity, one-argument env config, SSH directory creation, workspace root consistency, docs filename drift, Windows script filename drift, and full `main()` smoke path.
- [x] Run tests and capture expected red failures.
- **Status:** complete

### Phase 4: Green Fix
- [x] Add or replace OS detection call with defined behavior.
- [x] Make role selection logs go to stderr while stdout returns only role.
- [x] Create `~/.ssh` before key generation.
- [x] Make optional shell profile argument safe under `set -u`.
- [x] Use one canonical workspace root for repo cloning and later config.
- [x] Align README/AGENTS/docs with actual supported invocation and filenames.
- [x] Generate `AGENTS.md` compatibility guidance instead of conflicting `AGENT.md` language where practical.
- [x] Update changelog.
- **Status:** complete

### Phase 5: Verification
- [x] Run `bash test.sh`.
- [x] Run an isolated smoke execution with stubbed network/install commands.
- [x] Review `git diff`.
- **Status:** complete

### Phase 6: Delivery
- [ ] Commit changes with conventional commits.
- [ ] Push branch.
- [ ] Open PR linked to #113.
- [ ] Report results and residual risks.
- **Status:** pending

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| Treat this as a workspace-ops bug fix. | The active workspace status identifies onboarding alignment work under workspace operations. |
| Avoid real package installation or external cloning in smoke tests. | Verification must be safe in local and CI-like environments. |
| Prefer docs correction over standalone script packaging for this issue. | The repo is modular; making one downloaded file self-contained is broader packaging work. |

## Errors Encountered
| Error | Resolution |
|-------|------------|
| `/home/lgan/.claude/skills/planning-with-files/scripts/init-session.sh` missing. | Used installed helper at `/home/lgan/.agents/skills/planning-with-files/scripts/init-session.sh`. |
| First smoke test hung due test runner function named `main`. | Preserved sourced onboarding `main` as `onboarding_main` and renamed test runner to `run_tests`. |
