# GenCr@ft Studio — Workspace

Welcome to the GenCr@ft Studio primary workspace. This is a multi-repository ecosystem dedicated to the development of the **Aethel** multiplayer voxel RPG and the underlying **GenCr@ft Platform**.

## Bounded Workspaces

Our workspace is structured into five bounded domains to ensure focused delivery and clean separation of concerns.

### 🎮 1. Aethel Game (Aethel)
*   **Domain:** Core game engine, procedural generation, server, client, and voxel authority.
*   **Source of Truth:** [gcs-project-management/workspaces/aethel/STATUS.md](./gcs-project-management/workspaces/aethel/STATUS.md)
*   **Project Board:** Project #17
*   **Repositories:** `gcp-aethel-server`, `gcp-aethel-client`, `gcp-aethel-pcg`, `gcl-srv-authentication`, `gcl-srv-persistence`, `gcl-voxel-engine`, `gcl-ui-components`, `gcp-aethel-architecture`, `gcp-aethel-backlog`, `gcp-aethel-docs-gdd`, `gcp-aethel-docs-lw`, `gcp-aethel-docs-req`, `gcp-aethel-docs-external`

### ⚡ 2. EVAI Platform (EVAI Platform)
*   **Domain:** Developer agent pipelines, CLI orchestration, and Hermes API services.
*   **Source of Truth:** [gcs-project-management/workspaces/evai-platform/STATUS.md](./gcs-project-management/workspaces/evai-platform/STATUS.md)
*   **Project Board:** Project #18
*   **Repositories:** `gcs-plt-tools`, `gcs-plt-docs-req`

### 🤖 3. Agent Factory (Agent Factory)
*   **Domain:** AI Gem operational protocols, design blueprints, personas, and grader evaluations.
*   **Source of Truth:** [gcs-project-management/workspaces/agent-factory/STATUS.md](./gcs-project-management/workspaces/agent-factory/STATUS.md)
*   **Project Board:** Project #20
*   **Repositories:** `gcs-plt-gemop`, `gcs-plt-gembp`

### 🛠️ 4. Workspace Operations (Workspace Operations)
*   **Domain:** Onboarding scripts, CI/CD reusable workflows, OpenTofu IaC, and backup systems.
*   **Source of Truth:** [gcs-project-management/workspaces/workspace-ops/STATUS.md](./gcs-project-management/workspaces/workspace-ops/STATUS.md)
*   **Project Board:** Project #19
*   **Repositories:** `gcd-onboarding-scripts`, `gcd-ops-scripts`, `gcd-shared-actions`, `gcd-backup-utilities`, `gencraft-iac`

### 📚 5. Studio GenCraft (Studio GenCraft)
*   **Domain:** Studio manifestos, governance policies, security core, legal frameworks, and project tracking.
*   **Source of Truth:** [gcs-project-management/workspaces/studio-gencraft/STATUS.md](./gcs-project-management/workspaces/studio-gencraft/STATUS.md)
*   **Project Board:** Project #22
*   **Repositories:** `gcs-devops-standards`, `gcs-engineering-handbook`, `gcs-studio-handbook`, `gcs-security-core`, `gcs-studio-legal`, `gcs-project-management`, `gencr-ft.github.io`, `gct-repo-template-standard`, `gct-service-template-py`, `gct-ssot-templates`

---

## Portfolio Governance
*   **Project #21 (Recovery Portfolio):** Used strictly as a governance rollup and portfolio rollup. It is not an active contributor workspace.

---

## Getting Started — Onboarding Quick-Start

If you are willing to onboard our studio and start contributing to **Aethel** or the **GenCr@ft Platform**, follow this quick-start checklist:

### 1. Prerequisite Environment Check
Ensure you have the following system utilities loaded (or install them via your package manager):
* **Git** & **curl** / **unzip**
* **NVM** (Node Version Manager) or **Node.js v20 LTS**
* **Rustup** (Rust toolchain) & **wasm-pack**
* **Python v3.11+**
* **Pre-commit** (install via `pip install pre-commit`)

### 2. Run the Studio Onboarding Orchestrator
Execute the idempotent bootstrapping script to align your environment and verify system packages:
```bash
cd gcd-onboarding-scripts
./gft-onboarding.sh
cd ..
```

### 3. Sync Workspace Symlinks & relative Git Hooks
Use our platform tool `gft` (GenCr@ft Platform Tools) to automatically synchronize settings, relative path hooks, and Claude environment configurations:
```bash
gft workspace sync
```
This command syncs all local repository pre-commit hooks and configures Claude workspace settings without any absolute local path leaks.

### 4. Run Environment Diagnostics & Unit Tests
Before coding, run the diagnostic engine to confirm everything is set up correctly:
```bash
gft workspace doctor evai-platform
```
Then run the base unit tests to verify full workspace sanity:
```bash
./test-all.sh --no-integration
```

### 5. Find Your Bounded Workspace & Pick a Task
1. Look up the **STATUS.md** file for your assigned workspace under [gcs-project-management/workspaces/](./gcs-project-management/workspaces/) (e.g. `gcs-project-management/workspaces/aethel/STATUS.md`).
2. Read the "Active Work" and "Next Action" sections to understand the current engineering sprint.
3. Open **GitHub Project Board #16** (or your domain-specific project board #17, #18, #19, #20, #22) and select the next unassigned `Todo` issue.
4. Cut a branch conforming strictly to our naming standard (`feat/issue-ID-slug` or `fix/issue-ID-slug`) using:
   ```bash
   gft branch create <issue_id>
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
