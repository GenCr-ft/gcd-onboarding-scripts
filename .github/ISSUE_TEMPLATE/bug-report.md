---
name: "🐛 Bug Report"
about: Report a bug encountered in Gencraft systems, games, or tools.
title: 'BUG: [Briefly Describe the Bug]'
labels:
- type:bug
- status:new
- priority:TBD
assignees: ''
docId: PRO-TEMP-025
version: 2.0.0
authors:
- AI Compliance Agent
reviewers:
- Architecture Lead
creation_date: '2025-05-26'
language: en
summary: This document provides a template for reporting bugs related to Gencraft
  Studio and associated tools, outlining required information for effective issue
  tracking and resolution.
last_updated_date: '2026-05-23'
metadata:
  lifecycle-stage: draft
  keywords:
  - bug-report
  - gencraft-studio
  - issue-tracking
  - technical-writing
  - kb-template
  - qa-reporting
  scope: studio
  domain: production-management
  doc-type: template
  intended-audience:
  - contributors
  - ai-agents
  - governance-team
  - project-leads
  security-classification: l2_confidential
knowledgeGuardian:
- Antoine (GCT-MGT-PPM-001)
---
# Bug Report

## **Taxonomy Metadata**

- **Stream:** {{STREAM_ID}}
- **Priority:** {{PRIORITY_LEVEL}}
- **Affected Repo:** {{AFFECTED_REPO}}
- **Parent Epic / Backlog Reference:** {{BACKLOG_REFERENCE}}

## **Actionability Checklist**

- [ ] Does this issue target a single functional deliverable?
- [ ] Have all creative and technical dependencies (ADRs) been resolved or isolated?

---

**1. Bug Description:**
A clear and concise description of what the bug is.

**2. Steps to Reproduce:**
Steps to reliably reproduce the behavior:

1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error '...'

**3. Expected Behavior:**
A clear and concise description of what you expected to happen.

**4. Actual Behavior:**
A clear and concise description of what actually happened. Include error
messages if any.

**5. Environment & Context:**

- **Gencraft System/Game/Tool & Version:** [e.g., Gencraft Flagship Game v0.1.2,
  `gcs-studio-handbook` KB Search `Tool` v1.0]
- **GemID Reporting (if applicable):** [e.g., @Marc, @Iris]
- **Operating System (if relevant for client-side bugs):** [e.g., Windows 11,
  Linux (Kernel X.Y)]
- **Browser (if relevant for web tools/UI):** [e.g., Chrome vXX, Firefox vYY]
- **Relevant KB Article/Protocol (if bug relates to non-conformance):** [Link to
  KB article in `gcx-yyy` repo]
- **Related Task/Issue ID (if bug occurred during a specific task):** [Link to
  GitHub Issue]

**6. Severity & Priority (Initial Assessment - To be confirmed by QA
Lead/Product Owner):**

- **Proposed Severity:** [Critical / High / Medium / Low - Briefly justify based
  on impact on functionality/data]
    *Refer to `gcs-studio-handbook/02-knowledge-base-hub/KB-Domain-QA-Testing/Bug-Severity-Priority-Matrix.md` for guidance.*

**7. Logs, Screenshots, or Supporting Data:**
[Please attach or link to any relevant logs, screenshots, error messages, or
data that can help diagnose the issue. For AI Gems, provide relevant excerpts
from your operational logs or `Tool` outputs.]

**8. Additional Context (Optional):**
Any other information you believe is relevant to understanding or fixing this
bug.

---
*This bug report will be triaged by the QA Lead or the relevant
system/`Tool` owner.*

## AI Instructions

This section is reserved for AI-specific instructions and context for processing or updating this document.
