# GenCr@ft Studio — Workspace

Welcome to the GenCr@ft Studio primary workspace. This is a multi-repository ecosystem dedicated to the development of the **Aethel** multiplayer voxel RPG and the underlying **GenCr@ft Platform**.

## Overview

GenCr@ft Studio is an AI-augmented game development environment. We combine a hybrid voxel engine, emergent RPG mechanics, and a robust creator ecosystem. This workspace orchestrates several dozen specialized repositories across four primary domains:

1.  **Aethel Game Engine**: Core voxel logic, procedural generation (PCG), and real-time server/client synchronization.
2.  **Core Services**: High-availability microservices for authentication, persistence, and shared UI components.
3.  **Studio Platform**: AI agent blueprints, operational tools (DevSphere), and local development orchestration.
4.  **Governance & Standards**: The "Single Source of Truth" (SSoT) for engineering, legal, security, and design.

---

## Repository Map

### 🎮 Aethel Game (Project Aethel)
| Repository | Description | Classification |
|:-----------|:------------|:---------------|
| [`gcp-aethel-client`](./gcp-aethel-client) | Godot 4 game client (Desktop-first MVP) | application/service |
| [`gcp-aethel-server`](./gcp-aethel-server) | Authoritative real-time game server (Node.js/TypeScript) | application/service |
| [`gcp-aethel-pcg`](./gcp-aethel-pcg) | Procedural Content Generation engine (Rust/WASM) | application/service |
| [`gcl-voxel-engine`](./gcl-voxel-engine) | Server-side voxel authority library | library/package |
| [`gcp-aethel-backlog`](./gcp-aethel-backlog) | Engineering backlog and session reports | standards/docs |

### 🛠️ Core Services
| Repository | Description | Classification |
|:-----------|:------------|:---------------|
| [`gcl-srv-authentication`](./gcl-srv-authentication) | JWT-based auth service (NestJS) | application/service |
| [`gcl-srv-persistence`](./gcl-srv-persistence) | Player & world data persistence (NestJS/Prisma) | application/service |
| [`gcl-ui-components`](./gcl-ui-components) | Shared UI component library (Pending framework) | library/package |

### 🤖 Studio Platform (AI-Augmented Dev)
| Repository | Description | Classification |
|:-----------|:------------|:---------------|
| [`gcs-plt-tools`](./gcs-plt-tools) | **DevSphere**: Local dev orchestration and agent pipeline | CLI/tool |
| [`gcs-plt-gemop`](./gcs-plt-gemop) | AI Gem operational protocols and prompts | standards/docs |
| [`gcs-plt-gembp`](./gcs-plt-gembp) | Design blueprints for all 36 AI Gem roles | standards/docs |
| [`gencraft-iac`](./gencraft-iac) | Infrastructure as Code (OpenTofu/Terraform) | infrastructure/IaC |

### 📚 Governance & Handbooks
| Repository | Description | Classification |
|:-----------|:------------|:---------------|
| [`gcs-studio-handbook`](./gcs-studio-handbook) | Main studio operational handbook | standards/docs |
| [`gcs-engineering-handbook`](./gcs-engineering-handbook) | Cultural and technical engineering manifesto | standards/docs |
| [`gcs-devops-standards`](./gcs-devops-standards) | CI/CD, IaC, and tooling standards | standards/docs |
| [`gcs-security-core`](./gcs-security-core) | Security mandates and threat models | standards/docs |
| [`gcs-studio-legal`](./gcs-studio-legal) | Legal drafts (Privacy, EULA, IP) | standards/docs |

---

## Getting Started

To prepare your workstation for development across the entire studio:

1.  **Bootstrap Environment**:
    Use the onboarding script suite to install required tools (Docker, Node.js, Rust, Python, etc.) according to your assigned role.
    ```bash
    cd gcd-onboarding-scripts
    ./gft-onboarding.sh
    ```

2.  **Start Local Services**:
    Orchestrate the core platform and game server using DevSphere.
    ```bash
    cd gcs-plt-tools
    ./dev-up.sh
    ```

3.  **Run the Game**:
    Launch the Godot 4 client and connect to your local server.
    ```bash
    # Open gcp-aethel-client/project.godot in Godot 4.2+
    ```

## Development Standards

Every repository in this workspace follows strict quality gates:
- **Conventional Commits**: All messages must follow the [Angular convention](https://www.conventionalcommits.org/).
- **SSoT Documentation**: Every Markdown file must include a `docId` and YAML frontmatter.
- **Pre-commit Hooks**: Enforced via `pre-commit`; install locally with `pre-commit install` in any repository.

## Project Status

- **Phase 4 (Walking Skeleton)**: COMPLETE.
- **Phase 5 (PCG Integration)**: IN PROGRESS.

---

*This workspace is maintained by the GenCr@ft Studio Governance Crew.*
