# Progress

## 2026-06-06

- Created clean worktree `wi-96-gcd-onboarding-scripts` from `origin/main` on branch `fix/issue-96-workspace-bundle-drift`.
- Reproduced the failing `tests/test_workspace_files.sh` assertions from issue `#96`.
- Confirmed the failure source is stale content in `workspace/AGENTS.md`, not `workspace/README.md`.
- Updated the workspace bundle to:
  - reference the installed planning-with-files path under `/home/lgan/.agents/skills/...`
  - mention all five bounded workspaces plus Project `#21` governance rollup
  - replace the stale "pending GDD spec approvals" wording with current Phase 6 wording
- Validation:
  - `bash tests/test_workspace_files.sh` passes
  - `bash test.sh` passes
