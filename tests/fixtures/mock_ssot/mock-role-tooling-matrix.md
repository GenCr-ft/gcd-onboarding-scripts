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
    # NOUVELLE SECTION AJOUTÉE
    environment_variables:
      GFT_PROJECTS_HOME: "$HOME/gft_studio"
      GFT_LOG_LEVEL: "INFO"

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

  - name: devops-specialist
    description: "Role with its own specific tools and repos."
    inherits: lead-developer-tech-lead
    tools:
      - opentofu
      - shellcheck
    repositories:
      - "gencraft-iac"
    # NOUVELLE SECTION AJOUTÉE
    environment_variables:
      GFT_AWS_PROFILE: "gft-devops"
      # Une valeur vide indique au script de demander à l'utilisateur
      TF_VAR_github_token: ""
```
