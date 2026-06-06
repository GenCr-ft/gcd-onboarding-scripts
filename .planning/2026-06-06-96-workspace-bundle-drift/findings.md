# Findings

- `tests/test_workspace_files.sh` was failing because `workspace/AGENTS.md` lagged behind the current workspace contract.
- The failing assertions were documentation drift only:
  - stale planning init path (`/home/lgan/.claude/...` instead of `/home/lgan/.agents/...`)
  - missing bounded-workspace names outside `aethel`
  - stale "pending GDD spec approvals" phrase
- `workspace/README.md` already carried the bounded-workspace and project-board references; it did not require changes for `#96`.
