---
docId: GOV-PLAN-250
title: "[CODE] WI-250 — rename launcher to start_aethel.sh and fix WORKSPACE + PCG WASM"
version: 1.0.0
authors:
  - Prism (GCT-VFX-VXL-001)
status: in-progress
issue-id: GenCr-ft/gcd-onboarding-scripts#250
creation_date: '2026-07-18'
last_updated_date: '2026-07-18'
summary: "Rename workspace/run-walking-skeleton.sh to workspace/start_aethel.sh; fix WORKSPACE resolution; add conditional PCG WASM rebuild step; update test + docs."
metadata:
  artifact-class: knowledge
  classification:
    category: to-govern
    type: plan
  lifecycle-phase: approved
  scope: project-aethel
  domain: developer-tooling
  doc-type: plan
  security-classification: l2_confidential
---

# [CODE] WI-250 — rename launcher to start_aethel.sh and fix WORKSPACE + PCG WASM

Three fixes in one PR:
1. Rename workspace/run-walking-skeleton.sh to workspace/start_aethel.sh
2. WORKSPACE resolution: use dirname two levels up to reach workspace root
3. Conditional wasm-pack build before server build when pkg/ is absent or stale
4. Update tests/test_walking_skeleton_launcher.sh LAUNCHER_SRC path
