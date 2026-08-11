---
docId: GOV-PLAN-262
title: "[CODE] Add CLAUDE.md importing AGENTS.md"
version: 1.0.0
authors:
  - Claude
creation_date: '2026-08-11'
last_updated_date: '2026-08-11'
language: en
summary: One-line CLAUDE.md importing AGENTS.md so Claude Code can read this repo's authoritative instructions; part of the gemop#423 32-repo sweep
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#262
metadata:
  lifecycle-stage: draft
  scope: project-aethel
  domain: engineering
  doc-type: specification
  security-classification: l2_confidential
  keywords:
    - planning
    - agent-context
---

# WI-262 — `CLAUDE.md` shim

## Problem

Claude Code reads `CLAUDE.md`, not `AGENTS.md` (https://code.claude.com/docs/en/memory § AGENTS.md), so
`gcd-onboarding-scripts` had no Claude-readable project context — while the workspace `CLAUDE.md` designates each repo's
`AGENTS.md` as "the authoritative source for stack, commands, file boundaries, and prohibited patterns".

Measured by **GenCr-ft/gcs-plt-gemop#423**: **32 repos have `AGENTS.md`, 0 have `CLAUDE.md`**. Codex and
Antigravity read `AGENTS.md`; Claude Code read nothing repo-local. The two harnesses read disjoint files
for the same task.

## Change

One new file, `CLAUDE.md`, containing `@AGENTS.md`.

Import rather than symlink: on a Windows checkout without `core.symlinks` or Developer Mode, git
materialises a committed symlink as a regular file whose entire content is the literal string
`AGENTS.md` — Claude Code would load a `CLAUDE.md` saying `AGENTS.md` and silently drop every
instruction, with no error, on the platform least likely to notice. Windows is a live target in this
studio. Anthropic's guidance recommends the import for the same reason.

## Tier

`wi:lightweight` (GOV-STAN-010), label human-set. One file, one line: no code, schema, wire format, auth,
persistence, public API, enforcement-hook behaviour or clean-architecture boundary, so **no §5
never-eligible surface** is touched. `✅ LIFECYCLE:REFINE-LIGHTWEIGHT:PASS` recorded on the issue. The
adversary PR review at CLOSE still runs unconditionally (§4.1).

## Verification

- [x] `CLAUDE.md` is already in the SSoT linter's default `ignored_files`
      (`gcd-ops-scripts/src/ssot_linter/core/config.py:62`) and **no repo in the workspace overrides that
      list** — checked before filing, so the frontmatter-less shim cannot turn CI red.
- [x] Built in a git worktree off `origin/main`, so this repo's in-flight branch and any uncommitted work
      were never touched.
- [ ] AC-2 must-fire check: `/context` in a repo **without** the shim shows no `AGENTS.md` under
      *Memory files*; here it does. The negative case is run first — a check whose failing case was never
      exercised is not evidence.

## Relations

- Parent: GenCr-ft/gcs-plt-gemop#423
- Related: GenCr-ft/gcs-plt-gemop#377 — the workspace-root context files are untracked local-only
