---
docId: MOCK-GOV-POLI-001
title: Mock Role Tooling Matrix with Inheritance
---
# Mock SSoT for Testing Multi-Level Inheritance

```yaml
roles:
  - name: common-base
    description: "Universal tools and resources."
    tools:
      - git
      - github-cli
    repositories:
      - "gcs-studio-handbook"
      - "gcs-devops-standards"

  - name: lead-developer-tech-lead
    description: "Parent role with core tech tools and repos."
    inherits: common-base
    tools:
      - python
      - node-lts
      - docker
    repositories:
      - "gct-service-template-py"
      - "gcs-plt-tools"

  - name: gameplay-programmer
    description: "Child role inheriting from the lead dev."
    inherits: lead-developer-tech-lead
    # This role has no unique tools or repositories.

  - name: devops-specialist
    description: "Role with its own specific tools and repos."
    inherits: lead-developer-tech-lead
    tools:
      - opentofu
      - shellcheck
      - commitlint
      - yq
    repositories:
      - "gencraft-iac"
      - "gcd-onboarding-scripts"
```
