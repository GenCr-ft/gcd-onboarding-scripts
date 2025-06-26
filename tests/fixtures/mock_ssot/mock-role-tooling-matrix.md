---
docId: MOCK-GOV-POLI-001
title: Mock Role Tooling Matrix with Inheritance
---
# Mock SSoT for Testing Multi-Level Inheritance

```yaml
roles:
  - name: common-base
    description: "Universal tools."
    tools:
      - git
      - github-cli

  - name: lead-developer-tech-lead
    description: "Parent role with core tech tools."
    inherits: common-base
    tools:
      - python # <-- L'outil que nous cherchons est ici.
      - node-lts
      - docker

  - name: gameplay-programmer
    description: "Child role inheriting from the lead dev."
    inherits: lead-developer-tech-lead # <-- L'héritage correct est maintenant défini.
    # Ce rôle n'a pas d'outils propres.

  - name: devops-specialist
    description: "Role with its own specific tools."
    inherits: lead-developer-tech-lead # Hérite aussi pour être réaliste.
    tools:
      - opentofu
      - shellcheck
      - commitlint
      - yq
```
