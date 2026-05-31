# GenCr@ft Studio — Workspace

Welcome to the GenCr@ft Studio primary workspace. This is a multi-repository ecosystem dedicated to the development of the **Aethel** multiplayer voxel RPG and the underlying **GenCr@ft Platform**.

## Bounded Workspaces

Our workspace is structured into five bounded domains to ensure focused delivery and clean separation of concerns.

### 🎮 1. Aethel Game (Aethel)
*   **Domain:** Core game engine, procedural generation, server, client, and voxel authority.
*   **Source of Truth:** [gcs-project-management/workspaces/aethel/STATUS.md](file:///home/lgan/hxgn/dev/claude/exp/gcs-project-management/workspaces/aethel/STATUS.md)
*   **Project Board:** Project #17
*   **Repositories:** `gcp-aethel-server`, `gcp-aethel-client`, `gcp-aethel-pcg`, `gcl-srv-authentication`, `gcl-srv-persistence`, `gcl-voxel-engine`, `gcl-ui-components`, `gcp-aethel-architecture`, `gcp-aethel-backlog`, `gcp-aethel-docs-gdd`, `gcp-aethel-docs-lw`, `gcp-aethel-docs-req`, `gcp-aethel-docs-external`

### ⚡ 2. EVAI Platform (EVAI Platform)
*   **Domain:** Developer agent pipelines, CLI orchestration, and Hermes API services.
*   **Source of Truth:** [gcs-project-management/workspaces/evai-platform/STATUS.md](file:///home/lgan/hxgn/dev/claude/exp/gcs-project-management/workspaces/evai-platform/STATUS.md)
*   **Project Board:** Project #18
*   **Repositories:** `gcs-plt-tools`, `gcs-plt-docs-req`

### 🤖 3. Agent Factory (Agent Factory)
*   **Domain:** AI Gem operational protocols, design blueprints, personas, and grader evaluations.
*   **Source of Truth:** [gcs-project-management/workspaces/agent-factory/STATUS.md](file:///home/lgan/hxgn/dev/claude/exp/gcs-project-management/workspaces/agent-factory/STATUS.md)
*   **Project Board:** Project #20
*   **Repositories:** `gcs-plt-gemop`, `gcs-plt-gembp`

### 🛠️ 4. Workspace Operations (Workspace Operations)
*   **Domain:** Onboarding scripts, CI/CD reusable workflows, OpenTofu IaC, and backup systems.
*   **Source of Truth:** [gcs-project-management/workspaces/workspace-ops/STATUS.md](file:///home/lgan/hxgn/dev/claude/exp/gcs-project-management/workspaces/workspace-ops/STATUS.md)
*   **Project Board:** Project #19
*   **Repositories:** `gcd-onboarding-scripts`, `gcd-ops-scripts`, `gcd-shared-actions`, `gcd-backup-utilities`, `gencraft-iac`

### 📚 5. Studio GenCraft (Studio GenCraft)
*   **Domain:** Studio manifestos, governance policies, security core, legal frameworks, and project tracking.
*   **Source of Truth:** [gcs-project-management/workspaces/studio-gencraft/STATUS.md](file:///home/lgan/hxgn/dev/claude/exp/gcs-project-management/workspaces/studio-gencraft/STATUS.md)
*   **Project Board:** Project #22
*   **Repositories:** `gcs-devops-standards`, `gcs-engineering-handbook`, `gcs-studio-handbook`, `gcs-security-core`, `gcs-studio-legal`, `gcs-project-management`, `gencr-ft.github.io`, `gct-repo-template-standard`, `gct-service-template-py`, `gct-ssot-templates`

---

## Portfolio Governance
*   **Project #21 (Recovery Portfolio):** Used strictly as a governance rollup and portfolio rollup. It is not an active contributor workspace.

---

## Getting Started

To prepare your workstation for development across the entire studio:

1.  **Bootstrap Environment**:
    Use the onboarding script suite to install required tools (Docker, Node.js, Rust, Python, etc.) according to your assigned role.
    ```bash
    cd gcd-onboarding-scripts
    ./gft-onboarding.sh
    ```

2.  **Run Tests per Workspace**:
    Use our orchestrator command to test a specific bounded workspace:
    ```bash
    ./test-all.sh --aethel
    ```

## Development Standards

Every repository in this workspace follows strict quality gates:
- **Conventional Commits**: All messages must follow the Angular convention.
- **SSoT Documentation**: Every Markdown file must include a `docId` and YAML frontmatter.
- **Pre-commit Hooks**: Enforced via `pre-commit`; install locally with `pre-commit install` in any repository.

## Project Status

- **Phase 6 (State Persistence + Multiplayer)**: IN PROGRESS.

---

*This workspace is maintained by the GenCr@ft Studio Governance Crew.*
