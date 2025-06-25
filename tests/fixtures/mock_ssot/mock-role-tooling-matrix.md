---
docId: MOCK-GOV-POLI-001
title: Mock Role Tooling Matrix
---
# Mock SSoT for Testing

```yaml
roles:
  - name: common-base
    tools:
      - git
      - github-cli
  - name: devops-specialist
    inherits: common-base
    tools:
      - opentofu
      - shellcheck
      - commitlint
      - yq
  - name: gameplay-programmer
    inherits: common-base
    tools:
      - python
