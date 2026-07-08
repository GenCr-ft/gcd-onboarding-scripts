---
docId: GOV-PLAN-236
title: "[CODE] #236 — build voxel package before server"
version: 1.0.0
authors:
  - Antigravity
status: complete
issue-id: GenCr-ft/gcd-onboarding-scripts#236
github-issue: https://github.com/GenCr-ft/gcd-onboarding-scripts/issues/236
creation_date: '2026-07-08'
last_updated_date: '2026-07-08'
language: en
summary: >
  Build the local gcl-voxel-engine package and validate its main and types
  entrypoints in the run-walking-skeleton.sh launcher before building
  gcp-aethel-server.
---

# Build Voxel Package Before Server Launcher hardener

## TDD Cycles

- [x] Cycle 1: Build voxel package before server
  - [x] RED: Add test case asserting `gcl-voxel-engine` is built before `gcp-aethel-server` and verify fail-fast.
  - [x] GREEN: Insert package build and validation order.
- [x] Cycle 2: Fail fast on producer contract defects
  - [x] RED: Add test cases asserting fail-fast on build failure, missing `main`, and missing `types` entrypoint.
  - [x] GREEN: Implement deterministic error messaging and non-zero exit.
