# Gencraft: Consolidated List of Future Actions and Development Items

**Document Version:** 5.0 (Enriched for Actionability)
**Date:** May 13, 2025
**Status:** Under Review with Lug for Prioritization and Status Update
**Source:** Comprehensive review and enrichment of all previously identified future actions.

## 0. Introduction

This document provides a consolidated and structured overview of all identified pending actions, items to be developed, documents to be created or finalized, and strategic points requiring further in-depth work for the Gencraft virtual studio. Each action has been enriched to provide a clearer understanding of the tasks involved, potential responsible Gems, and expected outcomes, to facilitate execution by AI Gems or guidance for Lug.

The objective is to provide a clear, actionable checklist for the next phases of Gencraft's development.

## 1. Gem Roles & Organizational Structure Development

* **1.1. Finalize and Fully Populate `Studio-Organization-And-Roles.md`:**
    * **Action (Enriched):**
        1.  **Gather all source Gem description files** provided by Lug (Marketing, Design, Programming (remaining 5), Art (7/8), Audio, QA, Community & Support, Legal, Utilities).
        2.  For each Gem role not yet processed:
            * Extract key information (mission, responsibilities, interactions, deliverables) from the source file.
            * Translate French content to English if the primary source is in French.
            * Format the information strictly according to the agreed **Gem Role Description Template** (example: `gencraft_role_orion_liaison_gem_v1_en`). This includes assigning a preliminary `GemID` (pending final convention from point 1.2), defining "Reports To", detailing "Key Responsibilities", explicitly listing "Key Deliverables" with their SSoT locations, and defining "KC&T Specific Responsibilities".
            * Identify and list appropriate "Primary `Tools` Categories Utilized".
            * Ensure the "Adherence to Core Studio Documents & Universal Principles" section correctly links to `gencraft-universal-gem_principles_v1_en_final` and other foundational documents.
        3.  For Gem roles identified but without source files from Lug (e.g., `Iris`, `Véra`, `Léo`, specialized `Tools` developers, potential "KB Editor", "Finance Gem", "Security Officer"):
            * Draft their role descriptions from scratch based on our discussions and their defined responsibilities within the Gencraft protocols and KC&T framework.
        4.  **Consolidate all formatted Gem descriptions** (the 9 already validated + all new ones) into the single Markdown file: `gencraft-studio-handbook/00-Studio-Vision-And-Principles/Studio-Organization-And-Roles.md`. Ensure internal structuring by department with correct Markdown heading levels.
        5.  **Finalize Knowledge Guardian assignments:** For every section of the KB (in `gencraft-studio-handbook` and satellite `gencraft-xxx` repos), assign at least one Knowledge Guardian Gem in their role description and create a master list or map (potentially a new KB document `KB-Knowledge-Guardian-Map.md` or part of `Studio-Organization-And-Roles.md` or `KB-Architecture-And-Design.md`).
        6.  **Detail `CrewOps Arbitrator` and `Governance Crew` sections:** Ensure `Antoine`'s role as `CrewOps Arbitrator` (including his assistants `Véra`, `Isaac`, `Iris`) and the composition/mandate of the `Governance Crew` are fully detailed as per Protocols S12 and S13 within this document.
    * **Context:** This is a major and foundational deliverable for the "Gencraft Handbook". It's the SSoT for who does what.
    * **Responsible Gems (Anticipated):** Lug (providing source/validating), Gem (Assistant IA - drafting/formatting), `Antoine` (review/validation), `Iris` (consistency check).
    * **Deliverable:** The complete and validated `Studio-Organization-And-Roles.md` file.
    * **LUG'S STATUS for 1.1: En cours - Priorité Haute.**

* **1.2. Define `GemID` Convention:**
    * **Action (Enriched):**
        1.  **Research and Propose Conventions:** Gem (Assistant IA) to research common ID naming conventions in software/organizational contexts and propose 2-3 systematic, clear, and extensible conventions for unique `GemID`s. Examples previously discussed: `GCT-[DEPT_CODE]-[ROLE_ABBREV]-[SEQ_NUM]` or `GEM-[ROLE_NAME_SLUG]-[INSTANCE_ID]`. The proposal should include pros and cons for each, considering parsability by `Tools`, human readability, and future scalability (e.g., if multiple instances of the same Gem role are created).
        2.  **Present Options to Lug:** Submit the proposed conventions with justifications to Lug for decision.
        3.  **Document Chosen Convention:** Once Lug has made a decision, `Iris` (or Gem Assistant IA) documents the chosen `GemID` convention in two SSoT locations:
            * In `gencraft-studio-handbook/00-Studio-Vision-And-Principles/Studio-Organization-And-Roles.md` (e.g., in an introductory section explaining how Gems are identified).
            * In `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Contribution-And-Style-Guide.md` (as it's a naming/formatting standard).
        4.  **Plan and Execute Update Pass:** Plan a specific task (potentially for Gem Assistant IA or `Véra`) to go through all existing documents (especially `Studio-Organization-And-Roles.md` and protocol documents where GemIDs are mentioned) and replace all placeholder `GemID`s with IDs conforming to the new convention. This should be done via a dedicated PR for traceability.
    * **Context:** Consistent and unique `GemID`s are needed for `Gemma` (Gem configuration), `Véra` (tracking performance), `Tools` (assigning tasks, logging actions), and general clarity in all studio documentation and communication. Ensures uniqueness and predictability.
    * **Responsible Gems (Anticipated):** Gem (Assistant IA - proposing conventions), Lug (deciding), `Iris` (documenting convention), `Véra` or Gem Assistant IA (executing update pass).
    * **Deliverable:** Documented `GemID` convention in the KB, and all GemIDs in `Studio-Organization-And-Roles.md` updated.
* **1.3. Formalize "Knowledge Guardian" Assignments, Prerogatives, and `Tools`:**
    * **Action (Enriched):**
        1.  **Compile Definitive List:** Based on the fully populated `Studio-Organization-And-Roles.md` (from action 1.1), `Iris` (or Gem Assistant IA) compiles the definitive list of all Knowledge Guardian assignments, mapping GemIDs to specific KB domains, sections, or repositories (`gencraft-studio-handbook` and satellites `gencraft-xxx`).
        2.  **Define "Knowledge Guardian" Role Details:** `Antoine` and `Iris` to co-author a dedicated section within `Studio-Organization-And-Roles.md` (or a linked KB article like `KB-Role-Knowledge-Guardian.md` in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Gem-AI-Management/`) that formally defines:
            * **Specific Prerogatives:** e.g., final approval authority for new/updated content within their assigned domain (as per Protocol S5), right to request revisions from contributors, responsibility to initiate obsolescence reviews for their domain's content (Protocol S5.7).
            * **Expected Commitment/SLA:** Guidelines on expected responsiveness for reviewing KB proposals or addressing issues flagged in their domain (e.g., "Acknowledge new KB proposal within X business days").
            * **Specialized `Tools` Required:** Identify and list any specialized `Tools` a Knowledge Guardian might need beyond standard KB interaction `Tools`. Examples:
                * `KBReviewAssistanceTool`: To help check submitted KB content against the `KB-Contribution-And-Style-Guide.md` (formatting, frontmatter, style).
                * `ContentValidationTool`: (Advanced) To help check factual accuracy of new content against other established parts of the KB or even external trusted sources (if `Iris` provides this capability).
                * `ObsolescenceTriggerAnalysisTool`: (Advanced, for `Iris` or Guardians) To help identify content that might be becoming obsolete based on KB evolution or external triggers.
    * **Context:** Clarifies the authority, responsibilities, and operational expectations for Gems acting as Knowledge Guardians, ensuring the quality and integrity of the Gencraft KB.
    * **Responsible Gems (Anticipated):** `Antoine`, `Iris`, relevant Lead Gems (for input on prerogatives for their domains).
    * **Deliverable:** Updated `Studio-Organization-And-Roles.md` with clear KG assignments and a new/updated KB document detailing KG prerogatives, SLAs, and potential `Tools`.
* **1.4. Identify `Gemma` & `Proximo` Maintainers & Processes:**
    * **Action (Enriched):**
        1.  **Assign Maintainer Roles:** `Antoine` (in consultation with `Isaac` or "AI Enablement Team" Lead if defined) formally assigns the role of "Maintainer" for `Gemma` (Gem Generator) and `Proximo` (Prompt Generator). This might be a specific Gem (e.g., a "Lead AI Toolsmith" or "Meta-Gem Shepherd") or a shared responsibility within the "AI Enablement Team". Document this assignment in `Studio-Organization-And-Roles.md`.
        2.  **Document Update and Testing Processes:** The designated Maintainer(s) **must** create and document (e.g., in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Gem-AI-Management/Gemma-Proximo-Maintenance.md`) the processes for:
            * Updating `Gemma`'s knowledge of Gem Blueprints (from `gencraft-gem-blueprints`): How are new blueprints registered? How does `Gemma` know to use the latest version of a blueprint? How are blueprint changes versioned and tested?
            * Updating `Proximo`'s prompt templates and its contextual knowledge of Gencraft protocols, terminology (from `Glossary.md`), and KB structure: How does `Proximo` "learn" about new templates or studio standards to assist other Gems effectively?
            * Regression testing `Gemma` and `Proximo` after any significant update to their core logic, configurations, or the studio's foundational documents they rely on (KB, protocols). Define test cases and expected outcomes.
    * **Context:** Essential for keeping these critical Meta-Gems aligned with the evolving Gencraft studio, its KB, and its operational needs. Ensures they remain effective and don't propagate outdated information or behaviors.
    * **Responsible Gems (Anticipated):** `Antoine`, `Isaac` (or "AI Enablement Team" Lead), designated Maintainer(s) of `Gemma`/`Proximo`.
    * **Deliverable:** Updated `Studio-Organization-And-Roles.md` with maintainer assignments. New KB document `Gemma-Proximo-Maintenance.md`.
* **1.5. Detail `Governance Crew` Charter & Internal Decision Process:**
    * **Action (Enriched):**
        1.  The initially designated `Governance Crew` members (`Antoine` as Chair, `Béatrice`, `Isaac`, `Édouard`, `Véra`, `Orion`) **must** collaboratively draft the `Governance-Crew-Charter.md` document. This will be stored in `gencraft-studio-handbook/00-Studio-Vision-And-Principles/` (or a new `05-Governance/` folder if preferred for grouping governance docs).
        2.  The Charter **must** define and document:
            * **Precise Mandate:** The exact scope of decisions the `Governance Crew` is empowered to make (primarily focused on Global Operational Protocol evolutions as per S13, but potentially other studio-wide strategic standards).
            * **Member Roles and Responsibilities within the Crew:** e.g., Chair's role in facilitation, process for designating ad-hoc members for specific proposals.
            * **Meeting Cadences (if any):** Define if regular meetings are needed or if work is purely asynchronous via GitHub Issues. If meetings, define agenda templates, minute-taking (by whom, using what `Tool` and template).
            * **Decision-Making Mechanisms:** Explicitly define how decisions are reached (e.g., consensus preferred, majority vote if needed, `Antoine` as Chair has final say after full deliberation if no consensus).
            * **Process for Submitting Proposals *to* the Crew:** Reference Protocol S13 and the `gop-evolution-proposal-template.md`.
            * **Communication of Decisions:** How decisions are formally recorded (using `gop-decision-comment-template.md` in the PGE Issue) and communicated to the wider studio (as per S13.5).
            * **Interface with Lug (via `Orion`):** Clarify when and how the `Governance Crew` consults or seeks final approval from Lug for critical strategic evolutions.
    * **Context:** Protocol S13 established the `Governance Crew`; its internal operational rules and charter are needed for it to function effectively and transparently.
    * **Responsible Gems (Anticipated):** `Antoine` (as Chair, to lead drafting), all initial `Governance Crew` members (to contribute and approve).
    * **Deliverable:** The `Governance-Crew-Charter.md` document, reviewed and enacted.
* **1.6. Assess Need & Define "KB Editor" Gem Role:**
    * **Action (Enriched):**
        1.  `Antoine` and `Iris` (as primary KB architect/guardian) to conduct an assessment of the anticipated workload for final KB editing, formatting consistency, link integrity checking (beyond `Iris`'s automated `Tools`), and overall style guide adherence across all `gencraft-studio-handbook` and satellite KB content.
        2.  Consider the volume of expected contributions and the level of polish required.
        3.  If the need for a dedicated role is confirmed (i.e., if it exceeds `Iris`'s capacity or requires a different focus than `Iris`'s strategic KB architecture role):
            * Draft a role description for a "KB Editor" Gem. Responsibilities might include: final proofreading of KB articles before publication, ensuring adherence to `KB-Contribution-And-Style-Guide.md`, managing a "ready-to-publish" queue, potentially having merge rights on KB PRs after Knowledge Guardian technical/content approval.
            * Add this role to `Studio-Organization-And-Roles.md`.
        4.  If not a dedicated Gem, explicitly assign these final editing/consistency responsibilities to `Iris` and ensure her `Tools` and capacity can handle it.
    * **Context:** To ensure a high degree of polish, consistency, and quality for the Gencraft KB, making it more trustworthy and easier to use for all Gems.
    * **Responsible Gems (Anticipated):** `Antoine`, `Iris`.
    * **Deliverable:** A documented decision on the need for a "KB Editor" role. If affirmative, a role description in `Studio-Organization-And-Roles.md`.
* **1.7. Define "AI Enablement Team" / AI `Tool` Developers & Processes:**
    * **Action (Enriched):**
        1.  Formally define if Gencraft will have a dedicated "AI Enablement Team" or if `Tool`/MCP Server development is distributed among existing programming Gems/Crews. Document this decision in `Studio-Organization-And-Roles.md`.
        2.  If a team/function is formalized, assign a Lead (e.g., "Lead AI Toolsmith").
        3.  Create a document (e.g., `AI-Enablement-Charter-And-Processes.md` in `gencraft-studio-handbook/04-Tooling-And-Automation-Hub/` or in the team's own future `gencraft-ai-enablement-team` repository) detailing:
            * **Mandate:** Design, develop, test, deploy, document, and maintain all shared AI Gem `Tools` and MCP Servers. Provide support to other Gems on `Tool` usage.
            * **Development Lifecycle:** Agile/Scrum as per Protocol S15, or a specialized lifecycle for `Tool` development (e.g., rapid prototyping, iterative releases).
            * **Coding Standards for `Tools`:** (e.g., Python, Go - to be stored in `devops-standards` but referenced here).
            * **`Tool` Documentation Standards:** Enforce use of `tool-documentation-template.md` and `mcp-server-api-spec-template.md`.
            * **Design Review Process for New `Tools`:** (As per Point 2.3 of this list).
            * **Testing Strategy for `Tools`:** Unit, integration, and potentially "Gem-in-the-loop" testing.
            * **Interaction with other Gems/Crews:** How requirements for new `Tools` are gathered, how `Tools` are beta-tested, how support is provided.
    * **Context:** Crucial for building, maintaining, and evolving the sophisticated `Tool` ecosystem that Gencraft's AI Gems rely upon.
    * **Responsible Gems (Anticipated):** `Antoine`, `Isaac`, `Julien` (to define initial structure and needs).
    * **Deliverable:** Updated `Studio-Organization-And-Roles.md`. New `AI-Enablement-Charter-And-Processes.md` document.
* **1.8. Assess Need & Define "Finance & Admin" Gem Role:**
    * **Action (Enriched):**
        1.  `Antoine` and Lug to conduct a formal needs assessment for dedicated financial and administrative support, considering: current operational costs (cloud, licenses), complexity of S16 (Budget & Financial Management), and any anticipated administrative tasks (e.g., managing hypothetical freelance contracts, studio-level reporting beyond project reports).
        2.  If a dedicated role is justified, `Antoine` (with input from Lug) drafts the "Finance & Admin" Gem role description. This must include:
            * Clear responsibilities (e.g., executing S16 processes, preparing financial statements for `Antoine`/Lug, managing license renewal tracking, vendor interactions).
            * Required `Tools` (e.g., `ExpenseTrackingTool`, `FinancialReportGeneratorTool`, access to studio's chosen financial system/spreadsheet).
            * Reporting lines (likely to `Antoine`).
            * Key interactions (with `Antoine`, Leads for budget inputs, `Léo` for license costs, DevOps for cloud costs).
        3.  Integrate this role into `Studio-Organization-And-Roles.md`.
    * **Context:** For operational scaling, financial discipline, and freeing up `Antoine` from detailed financial admin.
    * **Responsible Gems (Anticipated):** Lug, `Antoine`.
    * **Deliverable:** Documented decision. If affirmative, a role description in `Studio-Organization-And-Roles.md`.
* **1.9. Assess Need & Define "Security Officer" Gem Role:**
    * **Action (Enriched):**
        1.  `Antoine`, `Isaac` (as current de-facto technical security lead), and `Adam` (DevOps Lead) to conduct a formal needs assessment for a dedicated "Security Officer" Gem. Consider: complexity of Protocol S8 (Information Security), scope of SIRT leadership, need for proactive security strategy development, continuous vulnerability management oversight, and driving security awareness across all Gems.
        2.  If justified, draft the "Security Officer" Gem role description. This must include:
            * Overall accountability for Gencraft's information security posture.
            * Leadership of the SIRT (Security Incident Response Team).
            * Ownership of Protocol S8 and its supporting KB documents (policies, standards).
            * Responsibility for defining and overseeing the vulnerability management program.
            * Driving security awareness "training" for Gems (via `Gemma` and KB content).
            * Required `Tools` (e.g., vulnerability scanners, security audit `Tools`, secure communication `Tools`).
            * Reporting lines (likely to `Antoine` or directly to Lug).
        3.  Integrate into `Studio-Organization-And-Roles.md` and update Protocol S8 responsibilities accordingly.
    * **Context:** For comprehensive and dedicated security leadership as Gencraft's systems and assets grow.
    * **Responsible Gems (Anticipated):** `Antoine`, `Isaac`, `Adam`.
    * **Deliverable:** Documented decision. If affirmative, a role description in `Studio-Organization-And-Roles.md` and updated S8.
* **1.10. Formally Document `CrewOps Arbitrator` Role & Assistants in `Studio-Organization-And-Roles.md`.**
    * **Action (Enriched):**
        1.  In `Antoine`'s role description within `Studio-Organization-And-Roles.md`, add a distinct sub-section for his function as `CrewOps Arbitrator` (as defined in Protocol S12).
        2.  This sub-section must detail: his authority to validate CSPs for global coherence, the process he follows (referencing S12.4), and his responsibility to identify GOP improvement needs from CSP trends.
        3.  Explicitly list `Véra`, `Isaac`, and `Iris` as formal "Assistants to the CrewOps Arbitrator" for their respective analytical inputs (Gem impact, technical coherence, KB conflicts). Detail how `Antoine` tasks them and how they provide their input for CSP reviews (e.g., via comments in the `type:csp-notification` Issue).
* **1.11. Clarify Departmental Attachment for `Orion` (Studio Liaison Gem) in `Studio-Organization-And-Roles.md`.**
    * **Action (Enriched):**
        1.  `Antoine` and Lug to discuss and decide on the optimal departmental attachment or reporting structure for `Orion`. Options:
            * D01: Management & Production (reporting to `Antoine` for operational coordination, while primary function is liaison for Lug).
            * D11: Utilities (as a specialized Meta-Gem studio support function).
            * Special Status: Reporting directly and exclusively to Lug, with operational interfaces to `Antoine`.
        2.  Document the chosen attachment and rationale in `Orion`'s role description in `Studio-Organization-And-Roles.md`. Ensure clarity on his operational interactions with `Antoine` regardless of formal reporting line.


# Gencraft: Consolidated List of Future Actions and Development Items

**Document Version:** 5.0 (Enriched for Actionability)
**Date:** May 13, 2025
**Status:** Under Review with Lug for Prioritization and Status Update
**Source:** Comprehensive review and enrichment of all previously identified future actions.

## 0. Introduction
*(Content as in previously generated version ID: `gencraft_consolidated_future_actions_v5_enriched`)*

## 1. Gem Roles & Organizational Structure Development
*(Content as in previously generated version ID: `gencraft_consolidated_future_actions_v5_enriched`)*

* **1.1. Finalize and Fully Populate `Studio-Organization-And-Roles.md`:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** Major deliverable for the "Gencraft Handbook". It's the SSoT for who does what.
    * **Responsible Gems (Anticipated):** Lug (providing source/validating), Gem (Assistant IA - drafting/formatting), `Antoine` (review/validation), `Iris` (consistency check).
    * **Deliverable:** The complete and validated `Studio-Organization-And-Roles.md` file.
    * **LUG'S STATUS for 1.1: En cours - Priorité Haute.**

* **1.2. Define `GemID` Convention:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** Consistent and unique `GemID`s are needed for `Gemma`, `Véra`, `Tools`, and general clarity.
    * **Responsible Gems (Anticipated):** Gem (Assistant IA - proposing), Lug (deciding), `Iris` (documenting), `Véra` or Gem Assistant IA (executing update pass).
    * **Deliverable:** Documented `GemID` convention in KB, all GemIDs updated.
    * **LUG'S STATUS for 1.2: [À définir par Lug]**

* **1.3. Formalize "Knowledge Guardian" Assignments, Prerogatives, and `Tools`:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** Clarifies authority and responsibility for KB quality.
    * **Responsible Gems (Anticipated):** `Antoine`, `Iris`, relevant Lead Gems.
    * **Deliverable:** Updated `Studio-Organization-And-Roles.md` and new/updated KB document on KG role.
    * **LUG'S STATUS for 1.3: [À définir par Lug]**

* **1.4. Identify `Gemma` & `Proximo` Maintainers & Processes:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** Essential for keeping Meta-Gems aligned and effective.
    * **Responsible Gems (Anticipated):** `Antoine`, `Isaac` (or "AI Enablement Team" Lead), designated Maintainer(s).
    * **Deliverable:** Updated `Studio-Organization-And-Roles.md`; new KB document `Gemma-Proximo-Maintenance.md`.
    * **LUG'S STATUS for 1.4: [À définir par Lug]**

* **1.5. Detail `Governance Crew` Charter & Internal Decision Process:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** Protocol S13 established the `Governance Crew`; its operational rules are needed.
    * **Responsible Gems (Anticipated):** `Antoine` (as Chair), all initial `Governance Crew` members.
    * **Deliverable:** The `Governance-Crew-Charter.md` document.
    * **LUG'S STATUS for 1.5: [À définir par Lug]**

* **1.6. Assess Need & Define "KB Editor" Gem Role:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** To ensure high polish and consistency of the Gencraft KB.
    * **Responsible Gems (Anticipated):** `Antoine`, `Iris`.
    * **Deliverable:** Documented decision; if affirmative, a role description.
    * **LUG'S STATUS for 1.6: [À définir par Lug]**

* **1.7. Define "AI Enablement Team" / AI `Tool` Developers & Processes:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** Crucial for building and maintaining the `Tool` ecosystem.
    * **Responsible Gems (Anticipated):** `Antoine`, `Isaac`, `Julien`.
    * **Deliverable:** Updated `Studio-Organization-And-Roles.md`; new `AI-Enablement-Charter-And-Processes.md`.
    * **LUG'S STATUS for 1.7: [À définir par Lug]**

* **1.8. Assess Need & Define "Finance & Admin" Gem Role:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** For operational scaling and financial discipline.
    * **Responsible Gems (Anticipated):** Lug, `Antoine`.
    * **Deliverable:** Documented decision; if affirmative, a role description.
    * **LUG'S STATUS for 1.8: [À définir par Lug]**

* **1.9. Assess Need & Define "Security Officer" Gem Role:**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Context:** For comprehensive and dedicated security leadership.
    * **Responsible Gems (Anticipated):** `Antoine`, `Isaac`, `Adam`.
    * **Deliverable:** Documented decision; if affirmative, a role description and updated S8.
    * **LUG'S STATUS for 1.9: [À définir par Lug]**

* **1.10. Formally Document `CrewOps Arbitrator` Role & Assistants in `Studio-Organization-And-Roles.md`.**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Responsible Gems (Anticipated):** `Antoine`, Gem (Assistant IA - drafting).
    * **Deliverable:** Updated section in `Antoine`'s role description in `Studio-Organization-And-Roles.md`.
    * **LUG'S STATUS for 1.10: [À définir par Lug]**

* **1.11. Clarify Departmental Attachment for `Orion` (Studio Liaison Gem) in `Studio-Organization-And-Roles.md`.**
    * **Action (Enriched):** *(Details as previously enriched and discussed)*
    * **Responsible Gems (Anticipated):** Lug, `Antoine`.
    * **Deliverable:** Documented decision and rationale in `Orion`'s role description.
    * **LUG'S STATUS for 1.11: [À définir par Lug]**

## 2. `Tools`, MCP Servers, and AI Gem Capabilities Development (Core of Sub-step 9.3)

* **2.1. Detailed Technical Specification of ALL Identified `Tools` & MCP Servers:**
    * **Action (Enriched):**
        1.  **Inventory & Prioritization:** `Antoine`, with the "AI Enablement Team" Lead (once defined, see 1.7) and key technical Leads (`Isaac`, `Julien`, `Adam`), to review the comprehensive list of conceptual `Tools` and MCP Servers mentioned throughout Protocols S1-S17 (as cataloged in `gencraft_kct_tools_categories_v1` and expanded in each protocol's "Impact on AI Gems" section). Prioritize this list based on criticality for studio operations and KC&T framework bootstrapping.
        2.  **Specification Sprint(s):** For each prioritized `Tool`/MCP Server, the "AI Enablement Team" (or designated Gem developers) **must** create a detailed technical specification document. This document **must** use the `tool-documentation-template.md` or `mcp-server-api-spec-template.md` (to be created, see 2.2).
        3.  **Content of Specifications:** Each specification **must** cover:
            * **Purpose:** What problem does this `Tool`/MCP Server solve for Gencraft Gems? Which protocol(s) does it support?
            * **Inputs:** Detailed definition of all input parameters, including name, data type (primitive, JSON schema, specific Gencraft object type), description, mandatory/optional status, and default values.
            * **Outputs:** Detailed definition of all outputs, including data type/schema, description of fields, and example outputs.
            * **Core Logic / Behavior:** High-level description of what the `Tool`/MCP Server does internally. For complex `Tools`, this might involve flowcharts or pseudo-code.
            * **Error Handling:** Comprehensive list of potential error codes or exception types the `Tool`/MCP Server can return, with clear descriptions of what each error means and suggested Gem recovery actions (retry, escalate, inform user). This aligns with Tool Design Principle #3.
            * **API Definition (for MCP Servers):** If it's an MCP Server, a formal API definition (e.g., OpenAPI/Swagger specification for RESTful services, gRPC .proto definition).
            * **Security Considerations:** Required permissions, authentication mechanisms, data sensitivity handled, potential attack vectors considered during design.
            * **Dependencies:** Other `Tools`, MCP Servers, KB articles, or Gencraft systems it relies on.
            * **Interaction Patterns:** How AI Gems are expected to call and interact with this `Tool`/MCP Server. Example call sequences.
            * **Performance Considerations/Targets (NFRs).**
        4.  **Storage of Specifications:** These specification documents will reside in the respective `Tool`/MCP Server's future code repository (e.g., `tool-gencraft-kb-search/docs/specification.md`) or in a centralized `gencraft-tooling-specs` repository if preferred. They are SSoT for development.
    * **Context:** This is the largest single block of pending technical design work, essential before any `Tool`/MCP Server development can begin. It directly implements Sub-step 9.3 of the KC&T Roadmap.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, designated Gem developers, `Isaac` (for architectural oversight), `Antoine` (for prioritization).
    * **Deliverable:** A collection of detailed technical specification documents for all prioritized `Tools` and MCP Servers.
    * **LUG'S STATUS for 2.1: [À définir par Lug - e.g., "À faire - Priorité Très Haute, commencer par Tools KC&T de base"]**

* **2.2. Standard Format for `Tool`/MCP Server Documentation (Templates):**
    * **Action (Enriched):**
        1.  The "AI Enablement Team" Lead (or `Isaac`) **must** draft the master templates: `tool-documentation-template.md` and `mcp-server-api-spec-template.md`.
        2.  These templates **must** include all sections required by point 2.1.3 (Purpose, Inputs, Outputs, etc.) and align with Tool Design Principle #6.
        3.  The templates are reviewed by `Antoine` and key technical Leads.
        4.  Once approved, they are stored in `gencraft-studio-handbook/02-Knowledge-Base-Hub/Templates/Document-Templates/` and become mandatory for all `Tool`/MCP Server documentation.
    * **Context:** Ensures all `Tools` and MCP Servers are documented consistently and comprehensively.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Isaac`.
    * **Deliverable:** Enacted `tool-documentation-template.md` and `mcp-server-api-spec-template.md`.
    * **LUG'S STATUS for 2.2: [À définir par Lug - e.g., "À faire - Priorité Haute, en parallèle de 2.1"]**

* **2.3. Design Review Process for New `Tools`/MCP Servers:**
    * **Action (Enriched):**
        1.  Define and document a formal Gencraft protocol (e.g., a new "S18 - Tool and MCP Server Design and Development Lifecycle Protocol" or as a sub-section of the "AI Enablement Team" charter from point 1.7) for how new `Tool` or MCP Server *designs* (i.e., their specifications from point 2.1) are proposed, reviewed, and approved *before* development work commences.
        2.  This protocol **must** specify:
            * Who can propose a new `Tool`/MCP Server (e.g., any Gem via their Lead, `Véra` identifying a need).
            * The format of the initial proposal (e.g., a GitHub Issue using a `new-tool-proposal-template.md`).
            * The designated reviewers for `Tool`/MCP Server specifications (e.g., "AI Enablement Team" Lead, `Isaac` for architecture, `Édouard` for DevOps impact, a "Security Champion" Gem, and the Lead of the primary Gem(s) who will use the `Tool`).
            * Criteria for review (alignment with Gencraft architecture, security, reusability, KC&T Tool Design Principles, cost-effectiveness).
            * How approval is traced (e.g., formal approval comment in the proposal Issue).
    * **Context:** Ensures `Tools` are well-designed, secure, aligned with studio needs, and avoid redundant efforts before investing in development.
    * **Responsible Gems (Anticipated):** `Antoine`, `Isaac`, "AI Enablement Team" Lead.
    * **Deliverable:** A documented design review protocol for `Tools`/MCP Servers within the Gencraft Handbook.
    * **LUG'S STATUS for 2.3: [À définir par Lug]**

* **2.4. Secret Management Strategy for `Tools`/MCP Servers:**
    * **Action (Enriched):**
        1.  `Adam` (DevOps Lead) and `Isaac` (Architect, or future Security Officer) **must** research, evaluate, and select a secure solution for managing all secrets (API keys, database credentials, service tokens, etc.) required by Gencraft `Tools` and MCP Servers. Options: GitHub encrypted secrets (for Actions), HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, Google Secret Manager, etc. The choice should consider security, ease of integration for AI `Tools`, auditability, and cost.
        2.  Document the chosen solution and the **detailed protocol for how `Tools` and MCP Servers securely request and receive credentials at runtime** (e.g., via an SDK, an internal MCP Server acting as a secrets broker). This protocol **must** ensure secrets are never hardcoded or logged.
        3.  Store this strategy and protocol in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Security/Secret-Management-Protocol.md`.
    * **Context:** Critical for the security of Gencraft operations (Protocol S8 and KC&T Tool Design Principle #4).
    * **Responsible Gems (Anticipated):** `Adam`, `Isaac`, (future) Security Officer.
    * **Deliverable:** Documented Secret Management Strategy and Protocol.
    * **LUG'S STATUS for 2.4: [À définir par Lug - e.g., "À faire - Priorité Très Haute"]**

* **2.5. Gem `Tool` Discovery Strategy:**
    * **Action (Enriched):**
        1.  Design a mechanism by which `Gemma` (when configuring new Gems) and potentially operational Gems (when needing a new capability) can discover available, approved, and versioned `Tools` and MCP Servers.
        2.  Options to consider:
            * A **structured manifest file** (e.g., YAML or JSON) in `gencraft-studio-handbook/04-Tooling-And-Automation-Hub/` (e.g., `available-tools-manifest.yml`) that lists all `Tools`/MCP Servers, their SSoT documentation link, current stable version, and a brief capability description. This file would be updated via PR when new `Tools` are published.
            * A dedicated **"Tool Registry" MCP Server** that `Gemma` or other Gems can query (e.g., `QueryAvailableToolsMCPService(capability_keywords) -> List[ToolInfo]`). This is more dynamic but more complex to build.
        3.  Document the chosen strategy and its usage in the "AI Enablement Team" charter or `Gem-Tools-Overview.md`.
    * **Context:** Essential for dynamic Gem configuration, `Tool` reuse, and managing the `Tool` ecosystem as it grows.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Isaac`, `Gemma`'s Maintainer.
    * **Deliverable:** Documented `Tool` Discovery Strategy and implemented mechanism (e.g., manifest file structure or API spec for Tool Registry).
    * **LUG'S STATUS for 2.5: [À définir par Lug]**

* **2.6. Explicit "Publication/Consumption" Process for `Tools`/MCP Servers:**
    * **Action (Enriched):**
        1.  Define and document (in the "AI Enablement Team" charter or a dedicated `Tool-Lifecycle-Management.md` in `gencraft-studio-handbook/04-Tooling-And-Automation-Hub/`) the complete lifecycle for Gencraft `Tools` and MCP Servers. This **must** include:
            * **Versioning Strategy:** e.g., Semantic Versioning (SemVer - Major.Minor.Patch) for all `Tools` and MCP Server APIs.
            * **Development and Testing Workflow:** How `Tools` are developed, tested (including security testing), and prepared for release.
            * **Publication Process:** How a new `Tool` or a new version of an existing `Tool`/MCP Server is formally "published" or "released" to the Gencraft studio (e.g., merging to `main` in its `gencraft-tool-xxx` repo, updating its entry in the `Tool` Discovery manifest/registry, deploying a new MCP Server version).
            * **Dependency Management:** How `Tools` declare and manage their dependencies on other `Tools`, MCP Servers, or libraries.
            * **Notification Mechanism:** How Gems (especially `Gemma` for blueprint updates and operational Gems using the `Tool`) are notified of new `Tool` versions, deprecations, or critical updates. (Could leverage `Iris` or a dedicated notification `Tool`).
            * **Deprecation Policy:** Process for deprecating and eventually retiring old `Tools` or versions.
    * **Context:** Ensures a controlled, stable, and manageable evolution of the Gencraft `Tool` ecosystem.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Isaac`, `Édouard`.
    * **Deliverable:** Documented `Tool` Lifecycle Management Protocol.
    * **LUG'S STATUS for 2.6: [À définir par Lug]**

* **2.7. Gem "Blueprint" Content & Structure (`gencraft-gem-blueprints`):**
    * **Action (Enriched):**
        1.  Define the precise schema (YAML or JSON structure) for Gem blueprint files stored in the `gencraft-gem-blueprints` repository. This schema **must** detail all configurable aspects of a Gem: `GemID` (placeholder for `Gemma` to fill), `RoleTitle`, `Department`, `CoreMissionGoal`, `KeyResponsibilities_MD_Path` (link to a Markdown snippet or section in `Studio-Organization-And-Roles.md`), `InitialTools_List_JSON` (list of `Tool` IDs and versions), `CoreKBLinks_JSON` (list of essential KB articles), `BackstoryPromptElements_JSON`, `GoalPromptElements_JSON`, specific operational parameters (e.g., verbosity, error handling strategy).
        2.  Define how blueprint versions are managed within `gencraft-gem-blueprints` (e.g., versioned files, Git tags).
        3.  Document the impact of blueprint updates on existing Gem instances (e.g., does `Gemma` attempt to "re-configure" active Gems, or do updates only apply to new instantiations? This links to Point 5.6).
        4.  Store this schema and versioning strategy documentation within the `README.md` of `gencraft-gem-blueprints`.
    * **Context:** Provides `Gemma` with a clear, machine-readable SSoT for how to instantiate and configure every Gencraft Gem role.
    * **Responsible Gems (Anticipated):** `Gemma`'s Maintainer, "AI Enablement Team" Lead, `Véra` (for input on performance-relevant parameters).
    * **Deliverable:** Documented Gem Blueprint schema and versioning strategy in `gencraft-gem-blueprints/README.md`.
    * **LUG'S STATUS for 2.7: [À définir par Lug]**

* **2.8. Define SSoT Repository (e.g., `gencraft-crewai-workflows`) & Structure for Studio-Wide CrewAI Definitions.**
    * **Action (Enriched):**
        1.  Formally create the `gencraft-crewai-workflows` GitHub repository (or confirm alternative name).
        2.  Define and document (in its `README.md`) its internal structure for storing Python code defining:
            * **Reusable Agent configurations** (which load Gem Blueprints from `gencraft-gem-blueprints` and instantiate them as CrewAI Agents with specific `Tools`).
            * **Crew definitions** (lists of Agents and their roles within the Crew).
            * **Task sequences and workflow logic** for common studio processes that are orchestrated by CrewAI.
        3.  Establish contribution guidelines (PR process, testing) for this repository.
        4.  Document how these workflows are cataloged or referenced from `gencraft-studio-handbook/04-Tooling-And-Automation-Hub/`.
    * **Context:** Provides the SSoT for the actual executable CrewAI code that orchestrates Gencraft's AI workforce.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Antoine` (for process definition input), `Isaac` (for architectural consistency).
    * **Deliverable:** Created and structured `gencraft-crewai-workflows` repository with initial `README.md` defining its purpose and conventions.
    * **LUG'S STATUS for 2.8: [À définir par Lug]**

* **2.9. Trigger/Decision Logic for AI Gem Traceability Actions:**
    * **Action (Enriched):**
        1.  For each Gencraft Operational Protocol (S1-S17) that requires AI Gems to perform a traceability action (e.g., Protocol S7: log a decision; Protocol S1: update deliverable status; Protocol S3: log incident actions), the "AI Enablement Team" and relevant Knowledge Guardians **must** specify the precise **triggers, conditions, or heuristics** that an AI Gem should use to decide *when* to perform that traceability action autonomously.
        2.  This logic should be documented either within the GOP itself (in the "Impact on AI Gems" section) or in a linked "AI Gem Implementation Guide" for that protocol.
        3.  Consider if these triggers are event-based (e.g., "after `Tool` X successfully completes"), data-driven (e.g., "if confidence score for output Y is below Z%"), or based on explicit instruction from another Gem.
    * **Context:** Moves beyond *what* to trace to *how an AI Gem knows when and how to initiate the tracing action* using its `Tools`. Critical for Gem autonomy.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, Knowledge Guardians of each protocol, `Véra`.
    * **Deliverable:** Updated GOP documents or linked "AI Gem Implementation Guides" with this logic defined.
    * **LUG'S STATUS for 2.9: [À définir par Lug]**

* **2.10. Heuristics/`Tools` for AI Gem Evaluation Assistance (KB proposals):**
    * **Action (Enriched):**
        1.  The "AI Enablement Team" (with input from `Iris` and Knowledge Guardians) to design and potentially develop:
            * **Heuristics for `Proximo`:** To help Gems evaluate if an observation or piece of information is significant enough to warrant a formal KB proposal (as per Protocol S5). `Proximo` could ask clarifying questions to the Gem based on these heuristics.
            * **A `KBProposalAssessmentTool`:** (Optional, advanced) A `Tool` that a Gem could use, providing its finding, and the `Tool` returns a "proposal strength" score or a recommendation on whether to proceed with a formal KB proposal Issue.
    * **Context:** To manage the quality and volume of KB proposals, ensuring Gems submit relevant and well-justified items.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Iris`, `Proximo`'s Maintainer.
    * **Deliverable:** Documented heuristics for `Proximo`. Specification (and potential PoC) for `KBProposalAssessmentTool`.
    * **LUG'S STATUS for 2.10: [À définir par Lug]**

* **2.11. Logic for Automatic Selection of Reviewers/Approvers by `Tools` for PRs/Issues KC&T.**
    * **Action (Enriched):**
        1.  Design and document the logic for `Tools` (e.g., `CreatePullRequestTool`, `SubmitIssueForReviewTool`, `CreateKCGovernanceIssueTool`) to automatically identify and assign appropriate reviewers or approvers for KC&T-related GitHub Issues and PRs.
        2.  This logic **must** be based on:
            * The SSoT `Studio-Organization-And-Roles.md` (which lists Knowledge Guardians for KB domains, Leads for departments, `CrewOps Arbitrator`, `Governance Crew` members).
            * The type of artifact being submitted (e.g., KB article, protocol change, CSP notification).
            * The specific KB domain or GOP affected.
        3.  `Iris` might maintain a "Reviewer Assignment Matrix" in the KB that these `Tools` can query.
    * **Context:** To streamline review processes and ensure the right experts are notified.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Iris`, `Antoine`.
    * **Deliverable:** Documented logic for reviewer/approver selection. Updated `Tool` specifications. Potential "Reviewer Assignment Matrix" in KB.
    * **LUG'S STATUS for 2.11: [À définir par Lug]**

* **2.12. Specification of Advanced Analytical `Tools` for `Iris` and `Véra`.**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) for the advanced `Tools` previously identified for `Iris` and `Véra`, such as:
        * For `Iris`: `KBRedundancyConflictDetectorTool`, `KBStructureCrawlerAndIndexerTool`, `KBLinkValidatorTool`, `CSPCoherenceAnalysisTool` (assisting `Antoine`), `QueryReportDataTool`.
        * For `Véra`: `GemWorkloadAnalysisTool`, `ProtocolAdherenceMonitoringTool`, `GemBehaviorPatternDetectorTool`, `GemPerformanceLogAggregatorTool`, `AnalyzeIncidentDataTool` (for Post-Mortems).
    * **Context:** These `Tools` are key to their specialized roles in maintaining KB quality and Gem/process performance.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Iris`, `Véra` (for requirements).
    * **Deliverable:** Detailed specification documents for each advanced `Tool`.
    * **LUG'S STATUS for 2.12: [À définir par Lug]**

* **2.13. Specification and Development of `Tools` for `Léo` (OSS Management).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for `Léo`'s `Tools`:
        * `SCAReportAnalysisTool`: To parse outputs from SCA tools (integrated by DevOps) and identify licenses/vulnerabilities.
        * `OSSLicenseInfoLookupTool`: To query external databases (SPDX, etc.) or internal KB (`Gencraft-AI-Open-Source-Policy.md`) for license details and compatibility.
        * `OSSKnowledgeBaseManagerTool`: To help `Léo` create and maintain the `OSS_Inventory_And_Compliance.md` files per project and the OSS sections of the KB.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Léo` (for requirements).
    * **Deliverable:** Spec docs, then developed `Tools`.
    * **LUG'S STATUS for 2.13: [À définir par Lug]**

* **2.14. Specification and Development of `Tools` for S3 (Incident Management).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for S3 `Tools`: `IncidentPriorityAssessorTool`, `CreateIncidentReportTool`, `UpdateSystemStatusPageTool`, `AccessRunbookTool`, `ExecuteDiagnosticScriptTool`, secure Action Execution `Tools` (e.g., `DeployCodeVersionTool`), `AnalyzeIncidentDataTool`, `DraftPostMortemSectionTool`.
* **2.15. Specification and Development of `Tools` for S6 (Reporting).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for S6 `Tools`: `GitHubQueryTool`, `PerformanceLogQueryTool`/`MetricsDBQueryTool` (MCPs), `MarkdownReportGeneratorTool`, `CreateReportPublicationIssueTool`, `ReportAccessAndParseTool`, `QueryReportDataTool`.
* **2.16. Specification and Development of `Tools` for S8 (Security).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for S8 `Tools`: `ClassifyDataTool`, `EncryptDataTool`, `RequestAccessTool`, `ReportVulnerabilityTool`, SAST/DAST/SCA `Tools` (integration), SIRT `Tools`, `SecurityPolicyLookupTool`.
* **2.17. Specification and Development of `Tools` for S9 (IP Management).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for S9 `Tools`: `SubmitIPDisclosureTool`, `RequestThirdPartyIPReviewTool`, `OriginalityCheckTool` (advanced), `OSSLicenseInfoLookupTool`, IP Catalog management `Tool`.
* **2.18. Specification and Development of `Tools` for S10 & S17 (Gem Onboarding & Development).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for S10/S17 `Tools` (for `Gemma`, new Gems, `Véra`, Leads).
* **2.19. Specification and Development of `Tools` for S12 (CSP Management).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for S12 `Tools`: `ProposeCSPTool`, `NotifyCrewOpsOfCSPTool`, `CSPCoherenceAnalysisTool`.
* **2.20. Specification and Development of `Tools` for S13 (GOP Evolution).**
    * **Action (Enriched):** Create detailed specifications (as per 2.1) and then plan development for S13 `Tools`: `CreateGOPProposalTool`, `PGEAnalysisTool`, `DecisionDocumentationTool`.

    *For points 2.14 to 2.20:*
    * **Context:** These are direct follow-ups from the protocol definitions.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, relevant protocol Knowledge Guardians (for requirements).
    * **Deliverable:** Detailed specification documents for each `Tool`, followed by development.
    * **LUG'S STATUS for 2.14-2.20: [À définir par Lug - Likely "À faire", with prioritization needed for which Tools come first]**

---
# Gencraft: Consolidated List of Future Actions and Development Items

**Document Version:** 5.0 (Enriched for Actionability)
**Date:** May 13, 2025
**Status:** Under Review with Lug for Prioritization and Status Update
**Source:** Comprehensive review and enrichment of all previously identified future actions.

*(Previous sections of this document, including Introduction, Section 1, and Section 2, are omitted here for brevity but are considered part of the ongoing review as per ID `gencraft_consolidated_future_actions_v5_enriched`)*

## 3. Templates and Standardized Formats Development

* **3.1. Create All Identified Markdown Templates (in `gencraft-studio-handbook/02-Knowledge-Base-Hub/Templates/`):**
    * **Action (Enriched):**
        1.  **Inventory and Prioritize Template Creation:** `Antoine` and `Iris` (as KB Architect) to review the full list of identified templates (Issue, PR, Document, Comment templates - see sub-bullets below). Prioritize creation based on which protocols and workflows will be implemented first.
        2.  **Assign Template Authorship:** For each template, assign a primary author Gem (e.g., `Iris` for generic KB templates, `Antoine` for project management templates, `Zoé` for bug report templates, `Henri`/`Léo` for legal/OSS templates, relevant Leads for specific document types).
        3.  **Drafting Phase (Iterative):** The assigned Gem author **must** create the `.md` file for each template in the correct sub-folder of `gencraft-studio-handbook/02-Knowledge-Base-Hub/Templates/` (i.e., `Issue-Templates/`, `Document-Templates/`, or a new `Comment-Templates/`).
            * Each template **must** include clear placeholders (e.g., `[BRIEFLY_DESCRIBE_ISSUE_HERE]`), instructional comments for users (human or AI Gem using the template), and any predefined frontmatter YAML fields or Markdown structural elements (headings, lists) required for consistency and machine-readability.
            * Reference the `KB-Contribution-And-Style-Guide.md` for formatting.
        4.  **Review and Validation:** Each drafted template **must** be submitted via a Pull Request to `gencraft-studio-handbook`. Reviewers should include `Iris` (for consistency with KB architecture and AI readability), `Proximo`'s maintainer (for usability in prompt generation), the Knowledge Guardian of any related protocol, and `Antoine`.
        5.  **Enactment:** Once approved and merged, the template is considered SSoT. `Iris` updates any central list of templates in `gencraft-studio-handbook/02-Knowledge-Base-Hub/Templates/README.md`.
    * **List of Templates to Create:**
        * **GitHub Issue Templates (`Issue-Templates/`):** `bug-report-template.md`, `feature-request-template.md`, `decision-record-template.md` (for ad-hoc S7 decisions), `lesson-learned-proposal-template.md` (for S5), `knowledge-proposal-template.md` (for S5/S8), `disagreement-formalization-template.md` (for S2), `incident-report-template.md` (for S3), `oss-evaluation-request-template.md` (for S9/Léo), `protocol-change-proposal-template.md` (for S12/S13), `obsolescence-review-request-template.md` (for S5), `csp-notification-template.md` (for S12), `code-of-conduct-report-template.md` (for CoC), `new-gem-request-template.md` (for S13/S17), `access-request-template.md` (for S8), `vulnerability-report-template.md` (for S8), `gop-evolution-proposal-template.md` (for S13), `inter-gem-request-template.md` (UOP 2.8).
        * **GitHub PR Templates (`PR-Templates/` - *new subfolder suggested*):** `pull_request_template.md` (general for all `gencraft-xxx` repos).
        * **Document Templates (`Document-Templates/`):** `kb-article-generic-template.md`, `gdd-feature-specification-template.md`, `technical-design-document-template.md`, `post-mortem-report-template.md`, `lug-directive-documentation-template.md` (for S7.4), `oss-inventory-compliance-template.md` (for S9/Léo), `runbook-template.md` (for S3), `gem-dossier-template.md` (for S10/S17/`Véra`), `tool-documentation-template.md` (for `Tool` specs), `mcp-server-api-spec-template.md` (for MCP specs), `csp-document-template.md` (for S12), all S6 Report Templates (e.g., `weekly-project-progress-report-template.md`), `budget-proposal-template.md` (S16), `financial-report-template.md` (S16), `onboarding-verification-report-template.md` (S10).
        * **Structured Comment Templates (Store in `Document-Templates/` or new `Comment-Templates/`):** `decision-log-comment-template.md` (for S2, S7, S13), `deliverable-approval-comment-template.md` (S1), `deliverable-rejection-comment-template.md` (S1), `csp-coherence-validation-comment-template.md` (S12).
    * **Context:** Foundational for ensuring consistency, quality, and machine-readability of all key Gencraft artifacts and communications on GitHub.
    * **Responsible Gems (Anticipated):** `Iris` (lead for KB/generic templates), `Antoine` (process/report templates), relevant Knowledge Guardians (for domain-specific templates), "AI Enablement Team" Lead (for `Tool`/MCP templates).
    * **Deliverable:** A comprehensive suite of version-controlled Markdown templates in `gencraft-studio-handbook/02-Knowledge-Base-Hub/Templates/`.
    * **Self-Check (Actionability for AI):** Sufficient. Once a template exists, an AI Gem (via `Proximo` or a specialized `Tool`) can be instructed to "Create a new Bug Report Issue using `bug-report-template.md` and populate it with the following information: [...]". The structure of the template itself guides the AI.
    * **LUG'S STATUS for 3.1: [À définir par Lug - e.g., "À faire - Priorité Très Haute, commencer par templates d'Issue critiques"]**

* **3.2. Develop `KB-Contribution-And-Style-Guide.md`:**
    * **Action (Enriched):**
        1.  `Iris` (as primary Knowledge Guardian for this guide), in collaboration with `Isaac` (for technical documentation standards) and `Édouard` (for "as-code" conventions), **must** draft the comprehensive `KB-Contribution-And-Style-Guide.md`.
        2.  This guide **must** include, at a minimum:
            * **Purpose and Scope** of the Gencraft KB.
            * **How to Propose New Content or Changes** (linking to Protocol S5).
            * **File Naming Conventions** for all KB articles and documents across `gencraft-studio-handbook` and satellite KB repos (e.g., `kebab-case-all-lowercase-with-version.md`).
            * **Folder Structure Conventions** (general principles, how to propose new top-level folders or `KB-Domain-XXXX.md` hub pages).
            * **Markdown Style Guide:** Specific Gencraft conventions for headings, lists, tables, code blocks, emphasis, links (internal relative paths, external), embedding images (from `assets/`).
            * **YAML Frontmatter Standards:** Mandatory and optional frontmatter fields for different document types (KB articles, protocols, reports, etc.), their data types, and allowed values (e.g., for `status:`). Include examples. This is critical for AI parsing.
            * **`GemID` Convention Reference:** Link to where the official `GemID` convention is documented (from point 1.2).
            * **ID Conventions for Reports, ADRs, Decisions:** Define how these are uniquely identified if not solely by file path or Issue number.
            * **Image Optimization and Storage Guidelines:** Rules for image formats, sizes, alt text, and storage in `gencraft-studio-handbook/assets/images/`.
            * **Asset Cleaning Process for `assets/`:** How to manage obsolete images.
            * **Glossary Usage:** How to refer to and propose additions to `Glossary.md`.
        3.  The draft guide is reviewed via PR by `Antoine`, key Leads, and potentially `Proximo`'s maintainer (for impact on prompt generation).
        4.  Once approved, it becomes the SSoT stored at `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Contribution-And-Style-Guide.md`.
    * **Context:** Essential for all KB contributors (AI and human) to ensure consistency, quality, and machine-readability of the entire Gencraft Knowledge Base.
    * **Responsible Gems (Anticipated):** `Iris` (lead author), `Isaac`, `Édouard`, `Antoine` (reviewer/approver).
    * **Deliverable:** Enacted `KB-Contribution-And-Style-Guide.md`.
    * **Self-Check (Actionability for AI):** Sufficient. An AI Gem (e.g., `Iris` drafting a KB article, or `Proximo` assisting another Gem) could be configured to strictly adhere to this guide. Its `Tools` (e.g., `MarkdownAuthoringTool`) would need to be "aware" of these standards.
    * **LUG'S STATUS for 3.2: [À définir par Lug - e.g., "À faire - Priorité Haute"]**

* **3.3. Standardized "Knowledge Guardian" Feedback Format for AIs:**
    * **Action (Enriched):**
        1.  `Iris` and the "AI Enablement Team" Lead (with input from Knowledge Guardians) **must** define a structured format or a set of keywords/phrases for Knowledge Guardians to use when providing feedback on KB proposals submitted by AI Gems (via GitHub Issues).
        2.  The goal is to make the feedback more easily parsable and actionable by the AI Gem author, enabling it to attempt revisions more autonomously. Examples:
            * Using specific prefixes: `KG_ACTION_REQUIRED: [Specific change needed in section X]`.
            * `KG_CLARIFICATION_NEEDED: [Question about Y]`.
            * `KG_SUGGESTION: [Consider adding Z]`.
            * Providing feedback as a checklist of changes.
        3.  This standardized feedback format **must** be documented within the `KB-Contribution-And-Style-Guide.md` (section on "Reviewing AI-Generated KB Proposals").
        4.  `Proximo` should be configured to help Knowledge Guardians use this format. AI Gems submitting KB content should be configured by `Gemma` to expect and parse this format.
    * **Context:** To improve the efficiency of the KB contribution cycle when AI Gems are authors.
    * **Responsible Gems (Anticipated):** `Iris`, "AI Enablement Team" Lead, `Proximo`'s Maintainer.
    * **Deliverable:** Documented standardized feedback format in `KB-Contribution-And-Style-Guide.md`.
    * **Self-Check (Actionability for AI):** Sufficient. An AI Gem author, upon receiving feedback via a `GitHubIssueMonitorTool`, could use a `ParseKGFeedbackTool` to extract actionable items if the feedback follows the defined structure.
    * **LUG'S STATUS for 3.3: [À définir par Lug]**

* **3.4. Create Templates for `Antoine`/`Iris` Communication Bulletins (for S14 & S6).**
    * **Action (Enriched):**
        1.  `Antoine` and `Iris` (as primary producers of studio-wide bulletins/digests – S6 reports, S14 communication plan) **must** define Markdown templates for these communications.
        2.  Templates should include standard sections (e.g., "Key Protocol Updates," "New KB Articles of Note," "Studio Achievements," "Upcoming Priorities").
        3.  Store these templates in `gencraft-studio-handbook/02-Knowledge-Base-Hub/Templates/Report-Templates/` (e.g., `studio-update-bulletin-template.md`, `iris-new-knowledge-digest-template.md`).
    * **Context:** To ensure consistency and efficiency in preparing regular studio-wide communications.
    * **Responsible Gems (Anticipated):** `Antoine`, `Iris`.
    * **Deliverable:** Enacted communication bulletin templates in the KB.
    * **Self-Check (Actionability for AI):** Sufficient. `Antoine` or `Iris` (or Gems assisting them) could use their `MarkdownReportGeneratorTool` with these templates.
    * **LUG'S STATUS for 3.4: [À définir par Lug]**

* **3.5. Explicit Data Format Standardization for AI (General KC&T):**
    * **Action (Enriched):**
        1.  The "AI Enablement Team" Lead and `Isaac` (Architect) **must** lead an initiative to define (or adopt existing industry standards like JSON Schema) formal schemas for key structured data objects that are frequently exchanged between Gencraft Gems or their `Tools` specifically for KC&T processes (beyond document frontmatter).
        2.  Examples: Schema for a "Traceability Event Log Entry," schema for `Véra`'s "Gem Performance Metric Set," schema for `Iris`'s "KB Link Validation Error Report."
        3.  These schemas **must** be documented and versioned, likely in a new directory: `gencraft-studio-handbook/02-Knowledge-Base-Hub/Data-Schemas/` or within `devops-standards`.
        4.  All relevant `Tools` and MCP Servers **must** be designed to produce and consume data compliant with these schemas. Validation `Tools` or libraries should be used.
    * **Context:** Ensures interoperability, reduces parsing errors for AI Gems, and facilitates reliable automated processing of KC&T data. Aligns with KC&T Guiding Principle #11.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Isaac`, `Édouard`.
    * **Deliverable:** Initial set of documented data schemas for key KC&T data objects. A new KB section for these schemas.
    * **Self-Check (Actionability for AI):** Sufficient. An AI Gem developer creating a `Tool` that produces or consumes this data would have a clear contract. AI Gems using these `Tools` would benefit from more reliable data exchange.
    * **LUG'S STATUS for 3.5: [À définir par Lug]**

* **3.6. Specify Format for `follow_up_actions_required_json` in Lug's Directives (S7.4).**
    * **Action (Enriched):**
        1.  `Orion` (Studio Liaison Gem) and `Antoine` **must** define the precise JSON structure for the `follow_up_actions_required_json` field within the `lug-directive-documentation-template.md`.
        2.  This structure should include fields like: `action_description: str`, `responsible_lead_gem_id: GemID`, `target_completion_date: Optional[YYYY-MM-DD]`, `status_tracking_issue_url: Optional[GitHubIssueURL]`.
        3.  Document this JSON schema within the comments of the `lug-directive-documentation-template.md` itself or in a linked schema file in `gencraft-studio-handbook/02-Knowledge-Base-Hub/Data-Schemas/`.
    * **Context:** To ensure that follow-up actions from Lug's directives are machine-readable and can potentially be used by `Tools` to automatically create tracking Issues or notify responsible Leads.
    * **Responsible Gems (Anticipated):** `Orion`, `Antoine`.
    * **Deliverable:** Updated `lug-directive-documentation-template.md` with the defined JSON schema for follow-up actions.
    * **Self-Check (Actionability for AI):** Sufficient. A `Tool` used by `Orion` or `Antoine` could parse this JSON to create follow-up tasks or reports.
    * **LUG'S STATUS for 3.6: [À définir par Lug]**

* **3.7. Define CVSS-like Scoring System for Vulnerabilities (for S8).**
    * **Action (Enriched):**
        1.  `Isaac` (Architect) or the future "Security Officer" Gem, in consultation with `Adam` (DevOps Lead), **must** define or adapt a CVSS-like scoring system for Gencraft to assess the severity of security vulnerabilities.
        2.  This system **must** define:
            * Key metrics/vectors (e.g., attack vector, complexity, privileges required, user interaction, impact on confidentiality/integrity/availability).
            * How these vectors map to a numerical score and/or qualitative severity levels (e.g., Critical, High, Medium, Low).
        3.  This scoring system **must** be documented as SSoT in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Security/Vulnerability-Scoring-System.md` and referenced by Protocol S8 (`Vulnerability-Management-Protocol.md`).
        4.  The `ReportVulnerabilityTool` (for S8) should guide the reporter to provide information relevant to these scoring vectors.
    * **Context:** Provides a standardized and objective way to assess and prioritize security vulnerabilities, enabling consistent response.
    * **Responsible Gems (Anticipated):** `Isaac`, (future) Security Officer, `Adam`.
    * **Deliverable:** Documented Vulnerability Scoring System in the KB.
    * **Self-Check (Actionability for AI):** Sufficient. An AI Gem (e.g., a security scanning `Tool` or `Isaac`/Security Officer using an assessment `Tool`) could use these defined criteria to help assign a severity score to a reported vulnerability.
    * **LUG'S STATUS for 3.7: [À définir par Lug]**

---
# Gencraft: Consolidated List of Future Actions and Development Items

**Document Version:** 5.0 (Enriched for Actionability)
**Date:** May 13, 2025
**Status:** Under Review with Lug for Prioritization and Status Update
**Source:** Comprehensive review and enrichment of all previously identified future actions.

*(Previous sections of this document, including Introduction, Section 1 (Gem Roles & Org Structure), Section 2 (`Tools`, MCPs, AI Capabilities), and Section 3 (Templates & Formats) are omitted here for brevity but are considered part of the ongoing review as per ID `gencraft_consolidated_future_actions_v5_enriched`)*

## 4. Knowledge Base (KB) and Studio Documentation Content Development

* **4.1. Develop Content for Placeholder Core Studio Documents (in `gencraft-studio-handbook/00-Studio-Vision-And-Principles/`):**
    * **Action (Enriched):**
        1.  **Assign Authorship:** `Antoine` (Producer), in consultation with Lug, **must** assign primary author Gems for `Studio-Culture-And-Values.md` (likely `Antoine` himself, with input from Lug and potentially `Véra` for AI Gem implications) and `Code-Of-Conduct.md` (likely `Henri` - Legal Counsel, with input from `Antoine` and `Véra`).
        2.  **Drafting Phase:** The assigned author Gem(s) **must** draft the content for these documents in English, ensuring they align with Gencraft's overall vision and the 13 KC&T Guiding Principles.
            * For `Studio-Culture-And-Values.md`: Elaborate on the core values identified (Innovation with Purpose, Rigorous Execution, Radical Transparency, etc.), providing concrete examples of "In Practice at Gencraft" for each, especially considering the AI Gem workforce.
            * For `Code-Of-Conduct.md`: Detail sections on Respectful Interaction, Constructive Communication, Collaborative Spirit, Integrity, Adherence to Protocols, Unacceptable Conduct, Reporting Violations, and Enforcement, with specific considerations for AI Gem interactions.
        3.  **Review and Validation (via PR to `gencraft-studio-handbook`):** Drafts are submitted as PRs. Reviewers **must** include `Antoine`, `Béatrice`, `Governance Crew` members, and Lug (via `Orion`).
        4.  **Enactment:** Once approved and merged, these documents become foundational SSoTs. `Iris` indexes them, and `Gemma` uses them to configure Gem `backstories`.
    * **Context:** These documents are critical for establishing Gencraft's operational ethos and behavioral expectations for all Gems.
    * **Responsible Gems (Anticipated):** Assigned Authors (e.g., `Antoine`, `Henri`), `Iris` (for KB integration), `Gemma`'s Maintainer (for incorporating into blueprints).
    * **Deliverable:** Enacted `Studio-Culture-And-Values.md` and `Code-Of-Conduct.md` in the KB.
    * **Self-Check (Actionability for AI):** Sufficient. Once these documents exist, `Gemma` can be configured by her maintainers to reference them when generating `backstories`. `Véra` can use them as a baseline for auditing Gem behavior.
    * **LUG'S STATUS for 4.1: [À définir par Lug - e.g., "À faire - Priorité Haute"]**

* **4.2. Develop Supporting KB Documents for Protocols S8-S17 (in `gencraft-studio-handbook`):**
    * **Action (Enriched):**
        1.  **Inventory & Assignment:** For each enacted Global Operational Protocol S8 through S17, `Antoine` and the protocol's primary Knowledge Guardian **must** identify all supporting KB documents explicitly mentioned as "To Be Developed" or "Placeholder" within that protocol (e.g., `Information-Classification-Policy.md` for S8, `Agile-Scrum-Parameters.md` for S15).
        2.  Assign authorship for each supporting document to the relevant Knowledge Guardian or a designated expert Gem.
        3.  **Drafting Phase:** Authors draft the content in English, ensuring it provides the detailed policies, standards, guidelines, or parameters required by the parent protocol. Documents **must** use the `kb-article-generic-template.md` or a more specific template if applicable, and include proper frontmatter.
        4.  **Storage Location:** Documents are placed in the correct KB domain folder within `gencraft-studio-handbook` (e.g., `Information-Classification-Policy.md` goes into `02-Knowledge-Base-Hub/KB-Domain-Security/`).
        5.  **Review and Validation (via PR):** Drafts are submitted as PRs to `gencraft-studio-handbook`, reviewed by the parent protocol's Knowledge Guardian, `Iris` (for KB consistency), and other relevant stakeholders (e.g., `Léo` for `Gencraft-AI-Open-Source-Policy.md`).
    * **List of Supporting Documents to Create (Examples from protocols):**
        * **For S8 (Security):** `Information-Classification-Policy.md`, `Access-Control-Policy.md`, `Data-Security-Standards.md`, `Secure-Development-Lifecycle-Policy.md`, `Vulnerability-Management-Protocol.md` (detailed version), `Security-Incident-Response-Plan.md` (SIRP).
        * **For S9 (IP):** `Third-Party-IP-Usage-Policy.md`, `Gencraft-AI-Open-Source-Policy.md`, `Gencraft-IP-Catalog.md` (defining format and maintenance process), `Acquired-IP-License-Inventory.md` (defining format and maintenance), Trademark usage guidelines.
        * **For S15 (Agile/Scrum):** `Agile-Scrum-Parameters.md` (sprint length, ceremony details), `Definition-Of-Done.md`.
        * **For S16 (Financial, in `KB-Domain-Finance-Admin/`):** `Approved-Budgets/` (structure and example), `Chart-Of-Accounts.md`, `Expenditure-Approval-Policy.md` (thresholds), `Financial-Reporting-Guidelines.md`.
    * **Context:** These documents provide the essential details and SSoTs that the higher-level protocols rely upon. Their absence would make the protocols difficult to implement.
    * **Responsible Gems (Anticipated):** Respective Knowledge Guardians for each protocol and its supporting documents (e.g., `Isaac`/Security Officer for S8 docs, `Henri`/`Léo` for S9 docs, `Antoine`/`Béatrice` for S15 docs, `Antoine`/Finance Gem for S16 docs).
    * **Deliverable:** A suite of enacted supporting KB documents, version-controlled in `gencraft-studio-handbook`.
    * **Self-Check (Actionability for AI):** Crucial. AI Gems following a protocol (e.g., S8) would use their `KnowledgeBaseSearchTool` to find and consult these specific policy/standard documents (e.g., "What is the Gencraft data classification for this information?"). The existence and clarity of these documents are vital for their compliance.
    * **LUG'S STATUS for 4.2: [À définir par Lug - e.g., "À faire - Prioritize based on which S-protocols are implemented first"]**

* **4.3. Create Specific KB Documents Referenced in Protocols S1-S7 & S10-S17 (General Utility/Reference):**
    * **Action (Enriched):**
        1.  **Inventory & Assignment:** `Antoine` and `Iris` to review protocols S1-S7 and S10-S17 to identify all other specific utility or reference KB documents mentioned as needing creation (not covered by 4.1 or 4.2).
        2.  Assign authorship to the most relevant Gem (e.g., `Adam` for `Incident-Commander-Assignments.md`, `Iris` for `Archive-Catalog.md` format).
        3.  Draft, store in appropriate KB location, review via PR, and enact.
    * **List of Documents (Examples):**
        * `Incident-Commander-Assignments.md` (for S3 - SSoT defining who is IC for what).
        * `System-Status.md` (for S3 - structure and update process definition for this page).
        * Initial set of `Runbooks/[IncidentType].md` (for S3 - at least 1-2 examples to establish format).
        * `Cloud-Storage-Guidelines.md` (for S4 - detailing chosen solution and usage rules).
        * "Map" of Knowledge Guardian domains (for S5, S10 - a central document listing all KG assignments, potentially part of `Studio-Organization-And-Roles.md` or `KB-Architecture-And-Design.md`).
        * Distribution matrix for S6 Report notifications (defining who gets which report).
        * KPIs and metrics definitions for each S6 Report type (detailed explanations of each metric).
        * `Archive-Catalog.md` (define its format and initial population process - for Archiving System).
        * `Data-Retention-Policy.md` (for Archiving System - content from `Henri`).
        * `Risk-Register.md` SSoT location (e.g., in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Product-Game-Design/`) and template.
        * Bug Severity/Priority Matrix SSoT location (e.g., in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-QA-Testing/`) and detailed criteria.
    * **Context:** These documents provide essential operational references and data that many protocols and Gems will use.
    * **Responsible Gems (Anticipated):** Assigned authors based on expertise (`Adam`, `Iris`, `Henri`, `Antoine`, `Zoé`).
    * **Deliverable:** Enacted utility and reference KB documents.
    * **Self-Check (Actionability for AI):** High. AI Gems will directly query these documents. E.g., an IC Gem for S3 needs `Incident-Commander-Assignments.md` to know if it's the right IC. `Tools` for S6 reporting need the KPI definitions.
    * **LUG'S STATUS for 4.3: [À définir par Lug - Prioritize based on operational needs]**

* **4.4. Define Specific "Initial Onboarding" Content per Gem Role (for S10 & S14).**
    * **Action (Enriched):**
        1.  For each key Gem role defined in `Studio-Organization-And-Roles.md`, the designated Crew Lead (or `Antoine` for studio-wide roles) **must** define a concise list of "Critical Initial Readings and `Tool` Familiarizations."
        2.  This list should include:
            * Pointers to the 3-5 most critical Global Operational Protocols for that role.
            * Pointers to key KB articles or satellite repositories (e.g., a Dev Gem must know `devops-standards/coding-standards/`).
            * Pointers to any Crew-Specific Protocols (CSPs) for their assigned Crew.
            * List of primary `Tools` they need to master and links to their documentation (in `gencraft-studio-handbook/04-Tooling-And-Automation-Hub/`).
        3.  This "Initial Onboarding Content List" for each role **must** be documented as part of its Gem Blueprint in `gencraft-gem-blueprints`.
        4.  `Gemma` will use this list during the instantiation process (Protocol S10.2.2) to provide targeted initial knowledge pointers to new Gems.
    * **Context:** Ensures new Gems are directed to the most vital information for their role immediately upon activation, accelerating their effectiveness.
    * **Responsible Gems (Anticipated):** Crew Leads, `Antoine`, `Gemma`'s Maintainer (for blueprint integration).
    * **Deliverable:** Updated Gem Blueprints in `gencraft-gem-blueprints` including this "Initial Onboarding Content List" for each role.
    * **Self-Check (Actionability for AI):** Crucial for `Gemma`. Also, a new Gem, if its onboarding protocol (S10) includes a task to "Process Initial Onboarding Content," could use this list to guide its initial KB exploration with its `KnowledgeBaseSearchTool`.
    * **LUG'S STATUS for 4.4: [À définir par Lug - To be done after roles in 1.1 are mostly defined]**

* **4.5. Define Strategy for IP of "Learned Behaviors" of Gems (S9.2.1).**
    * **Action (Enriched):**
        1.  `Henri` (Legal Counsel), `Léo` (OSS Specialist), `Véra` (Gem Quality), `Isaac` (Architect), and the "AI Enablement Team" Lead **must** form a working group to conduct a strategic discussion on how Gencraft identifies, documents, and potentially protects Intellectual Property arising from unique, effective, and non-obvious "learned behaviors," emergent strategies, or novel configurations of its AI Gems (beyond the direct code of their `Tools` or blueprints).
        2.  This discussion should consider:
            * What constitutes a "protectable learned behavior" in an AI context?
            * How can such behaviors be reliably identified and documented by `Véra` or other Gems?
            * What are the mechanisms for Gencraft to assert ownership or protect such emergent IP (e.g., trade secrets, patents on AI training methods if applicable, copyright on unique configurations if they meet creative criteria)?
            * How does this interact with the licenses of underlying AI models or frameworks used by Gencraft?
        3.  The outcome of this discussion **must** be a documented "Strategy for Managing IP of Emergent AI Gem Behaviors," stored in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Marketing-Sales-Legal/IP-Management/AI-Emergent-IP-Strategy.md`.
    * **Context:** This is a complex, forward-looking IP issue specific to an AI-driven studio. A clear strategy is needed to protect potential competitive advantages.
    * **Responsible Gems (Anticipated):** `Henri` (lead), `Léo`, `Véra`, `Isaac`, "AI Enablement Team" Lead.
    * **Deliverable:** Documented strategy paper on AI Emergent IP.
    * **Self-Check (Actionability for AI):** Primarily a strategic human-level task. However, AI Gems like `Véra` might need `Tools` or heuristics (derived from this strategy) to help *identify* potentially novel behaviors that warrant IP review.
    * **LUG'S STATUS for 4.5: [À définir par Lug - e.g., "À faire - Strategic importance, medium term"]**

---
# Gencraft: Consolidated List of Future Actions and Development Items

**Document Version:** 5.0 (Enriched for Actionability)
**Date:** May 13, 2025
**Status:** Under Review with Lug for Prioritization and Status Update
**Source:** Comprehensive review and enrichment of all previously identified future actions.

*(Previous sections of this document, including Introduction, Section 1 (Gem Roles & Org Structure), Section 2 (`Tools`, MCPs, AI Capabilities), Section 3 (Templates & Formats), and Section 4 (KB & Studio Doc Content) are omitted here for brevity but are considered part of the ongoing review as per ID `gencraft_consolidated_future_actions_v5_enriched`)*

## 5. Broader Studio Infrastructure and Process Development

* **5.1. Define Standards and Templates for New Specialized Repositories (`gencraft-xxx`).**
    * **Action (Enriched):**
        1.  `Édouard` (DevOps Strategy), in collaboration with `Isaac` (Architect) and relevant Leads (e.g., "AI Enablement Team" Lead, `Julien` for game code repos), **must** define and document (in `devops-standards`) standardized templates or checklists for creating new `gencraft-xxx` specialized repositories.
        2.  These standards **must** cover:
            * **Default `README.md` structure:** (e.g., Project Purpose, How to Build/Run, Key Contacts/Knowledge Guardians, Link to detailed KB documentation).
            * **Required base files:** (e.g., `.gitignore` appropriate for the repo type, `LICENSE` file - referencing Gencraft's chosen default or requiring `Léo`'s approval for specific OSS licenses).
            * **Initial branch structure:** (e.g., `main`, `develop`).
            * **Required GitHub settings:** (e.g., branch protection rules, default labels for Issues/PRs, Issue/PR template locations if not using org-level).
            * **Directory structure conventions** for common repository types (e.g., `Tool` repos, MCP Server repos, game component repos, KB satellite repos like `gencraft-requirements`).
        3.  `Camille` (DevOps Automation) may develop a `Tool` or GitHub Action to help automate the creation of new repositories based on these templates.
    * **Context:** Ensures consistency, discoverability, and adherence to best practices for all new Gencraft code and documentation repositories.
    * **Responsible Gems (Anticipated):** `Édouard` (lead), `Isaac`, relevant Leads, `Camille`.
    * **Deliverable:** Documented standards and templates for new repositories in `devops-standards`. Potential automation `Tool`/script.
    * **Self-Check (Actionability for AI):** Sufficient. An AI Gem (e.g., `Adam` or a Lead requesting a new repo, or `Camille` automating its creation) could use these standards. `Véra` could audit new repos against these standards.
    * **LUG'S STATUS for 5.1: [À définir par Lug]**

* **5.2. Detail "Interface Contracts" between Repos & Gems:**
    * **Action (Enriched):**
        1.  For key inter-repository or inter-Gem information flows that are not already covered by specific `Tool`/MCP Server API specifications (from Action 2.1), the "AI Enablement Team" Lead, `Iris` (for KB linking), and `Gemma`'s Maintainer **must** define and document these "interface contracts."
        2.  **Examples of interfaces to detail:**
            * **`Iris`'s KB Linking/Indexing:** How `Iris`'s `Tools` (`KBStructureCrawlerTool`, `KBLinkValidatorTool`) expect to discover and parse links between `gencraft-studio-handbook` and satellite `gencraft-xxx` KB repositories. What metadata or link formats are required? How are new satellite KBs "registered" with `Iris`? (Refines Action 5.8).
            * **`Gemma`'s Access to `gencraft-gem-blueprints`:** The precise file format (YAML/JSON schema from Action 2.7) and API/method `Gemma` uses to read Gem Blueprints, role descriptions from `Studio-Organization-And-Roles.md`, and initial onboarding content (Action 4.4) for configuring new Gems.
            * **Data Exchange Formats (General):** Reference the output of Action 3.5 (Explicit Data Format Standardization for AI) for any other common data objects passed between Gems or `Tools` that don't have a full MCP Server API.
        3.  These contracts **must** be documented in a relevant SSoT location (e.g., `Iris`'s `Tool` documentation, `Gemma`'s blueprint documentation in `gencraft-gem-blueprints/README.md`, or a dedicated `Gencraft-Inter-Gem-Interface-Contracts.md` in `gencraft-studio-handbook/04-Tooling-And-Automation-Hub/`).
    * **Context:** Ensures that Gems and `Tools` that need to exchange data or access information across different SSoT repositories or systems can do so reliably and predictably.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Iris`, `Gemma`'s Maintainer, `Isaac` (for architectural consistency).
    * **Deliverable:** Documented interface contracts for key Gencraft information flows.
    * **Self-Check (Actionability for AI):** Crucial. AI Gems and their `Tools` are the primary consumers of these contracts. For example, `Gemma` *cannot* function without a clear contract for reading blueprints. `Iris` *cannot* maintain KB coherence without a contract for link formats and repo registration.
    * **LUG'S STATUS for 5.2: [À définir par Lug]**

* **5.3. Develop Initial Vision & Requirements for Studio GUI (`gencraft-studio-portal-gui`).**
    * **Action (Enriched):**
        1.  `Antoine` (Producer) and `Béatrice` (Product Manager), with input from Lug (via `Orion`) and potentially `Hélène` (UX/UI Designer), **must** lead a requirements gathering and vision definition phase for a potential Gencraft Studio GUI.
        2.  This phase **must** produce a **High-Level Requirements Document** for the GUI, covering:
            * **Target Users:** Primarily Lug? `Antoine`? Other Lead Gems?
            * **Key Use Cases:** What critical tasks would the GUI facilitate (e.g., visualizing overall project status from S6 reports, browsing the KB `gencraft-studio-handbook` in a user-friendly way, monitoring high-level Gem/Crew performance from `Véra`'s reports, initiating specific high-level studio processes or reports)?
            * **Information to Display:** What key data from Gencraft's systems (GitHub, KB, `Tool` outputs) needs to be surfaced?
            * **Key Functionalities:** What actions should users be able to perform via the GUI?
            * **Non-Functional Requirements (Initial):** e.g., security, responsiveness, accessibility.
            * **Technology Stack Considerations (Preliminary):** Any preferences or constraints?
        3.  This document will serve as the basis for deciding whether to proceed with GUI development and for creating its SSoT repository (`gencraft-studio-portal-gui`) and detailed technical specifications.
    * **Context:** A GUI could significantly enhance Lug's ability to oversee and interact with the Gencraft virtual studio. Clear requirements are needed before any development.
    * **Responsible Gems (Anticipated):** `Antoine`, `Béatrice`, Lug (for vision), `Hélène` (for UX input).
    * **Deliverable:** A High-Level Requirements Document for the Gencraft Studio GUI, stored in `gencraft-requirements` or a new `gencraft-studio-portal-gui/docs/` folder.
    * **Self-Check (Actionability for AI):** This task is primarily for human stakeholders to define a human-facing tool. However, AI Gems like `Iris` or `Véra` might eventually have `Tools` to *provide data to* this GUI via defined APIs or data formats (Action 3.5).
    * **LUG'S STATUS for 5.3: [À définir par Lug]**

* **5.4. Develop Error Handling Protocols for KC&T Processes Themselves.**
    * **Action (Enriched):**
        1.  `Véra` (Gem Quality) and `Antoine` (Producer), with input from the "AI Enablement Team" Lead and `Adam` (DevOps Lead), **must** define and document a Gencraft protocol for how failures *within the KC&T processes or `Tools` themselves* are detected, reported, triaged, and resolved.
        2.  This protocol (e.g., "S18 - KC&T System Incident Management Protocol" in `gencraft-studio-handbook/01-Operational-Protocols/`) **must** cover:
            * **Detection:** How are KC&T process failures detected (e.g., a `Tool` fails to write a trace to a GitHub Issue, `Iris`'s indexer crashes, a Gem reports it cannot follow a protocol due to a `Tool` bug)?
            * **Reporting:** How do Gems or `Tools` report these "meta-incidents"? (e.g., a specific `type:kct-tool-failure` Issue in `gencraft-operations` or the `Tool`'s own repository).
            * **Triage & Ownership:** Who is responsible for triaging these meta-incidents (`Véra`? "AI Enablement Team" Lead? `Adam` for infra-related `Tool` issues?).
            * **Resolution & Escalation:** Process for fixing the faulty `Tool`, data, or protocol.
            * **Impact Assessment:** How to assess if a KC&T failure has compromised the integrity of past traces or KB entries, and what corrective data actions are needed.
    * **Context:** Ensures the reliability and trustworthiness of the KC&T framework itself.
    * **Responsible Gems (Anticipated):** `Véra`, `Antoine`, "AI Enablement Team" Lead, `Adam`.
    * **Deliverable:** A new "S18 - KC&T System Incident Management Protocol" document.
    * **Self-Check (Actionability for AI):** Crucial. If an AI Gem's `Tool` for, say, logging a decision (S7) fails, the Gem needs a defined fallback or escalation procedure. `Véra` needs this protocol to manage the quality of the KC&T system.
    * **LUG'S STATUS for 5.4: [À définir par Lug]**

* **5.5. Develop Conflict Resolution Process between "Knowledge Guardians."**
    * **Action (Enriched):**
        1.  `Antoine` (as `CrewOps Arbitrator` and overall process owner), with input from `Iris` (as KB Architect) and the `Governance Crew`, **must** define and document a specific conflict resolution process for when Knowledge Guardians disagree on matters related to KB content, structure, or standards within their domains.
        2.  This process (e.g., as a sub-section in Protocol S2: Disagreement Management, or a new "S19 - KB Governance Conflict Resolution Protocol") **must** detail:
            * **Scope:** What types of disagreements does this cover (e.g., conflicting information in different KB sections, disputes over style guide application, disagreements on obsolescence decisions).
            * **Initial Resolution Attempt:** Knowledge Guardians involved should first attempt direct resolution (traced in a GitHub Issue in `gencraft-studio-handbook`).
            * **Escalation Path:** If unresolved, escalate to `Iris` (for matters of KB structure/consistency) or `Antoine` (for broader policy or resource implications).
            * **Final Arbitration:** `Antoine` (potentially after consulting the `Governance Crew` or Lug for major KB-wide issues) makes the final binding decision.
            * **Traceability:** All steps and decisions traced via GitHub Issues.
    * **Context:** Ensures that disagreements about the KB itself (which is the SSoT) are resolved efficiently and authoritatively.
    * **Responsible Gems (Anticipated):** `Antoine`, `Iris`, `Governance Crew`.
    * **Deliverable:** Documented KB Governance Conflict Resolution Protocol.
    * **Self-Check (Actionability for AI):** Sufficient. An AI Gem acting as a Knowledge Guardian, if it detects a conflict with another Guardian's domain or a proposed change, would know the process to follow. `Iris` could use this protocol if her `Tools` detect systemic KB inconsistencies.
    * **LUG'S STATUS for 5.5: [À définir par Lug]**

* **5.6. Develop `Gemma`/`Proximo` Configuration Update Protocol.**
    * **Action (Enriched):**
        1.  The Maintainer(s) of `Gemma` and `Proximo` (identified in Action 1.4), in collaboration with `Iris` (for KB changes) and `Véra` (for Gem behavioral needs), **must** define and document the precise protocol for how changes to the Gencraft KB (new templates, updated protocols, new terminology in `Glossary.md`) trigger a review and potential update of `Gemma`'s blueprints (in `gencraft-gem-blueprints`) and `Proximo`'s prompt strategies/templates (in its config repo).
        2.  This protocol (e.g., in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Gem-AI-Management/Gemma-Proximo-Update-Protocol.md`) **must** cover:
            * **Notification Trigger:** How are `Gemma`/`Proximo` maintainers formally notified of KB changes relevant to them? (e.g., `Iris` or Knowledge Guardians creating specific Issues in `gencraft-gem-blueprints` or the `Tool` config repos, labeled `type:config-update-needed`).
            * **Impact Assessment:** How do maintainers assess which Gem blueprints or prompt templates are affected?
            * **Update Process:** How are changes to blueprints/templates drafted, tested (e.g., generate a test Gem, test a prompt), reviewed, and deployed? (Likely via PRs in `gencraft-gem-blueprints` or their config repos).
            * **Versioning:** How are versions of blueprints and prompt template sets managed?
            * **Communication:** How are changes to `Gemma`/`Proximo` capabilities communicated to the studio (e.g., to `Antoine`, Leads, `Véra`)?
    * **Context:** Ensures that these critical Meta-Gems remain synchronized with the evolving Gencraft operational environment.
    * **Responsible Gems (Anticipated):** `Gemma`'s Maintainer, `Proximo`'s Maintainer, `Iris`, `Véra`.
    * **Deliverable:** Documented `Gemma`/`Proximo` Configuration Update Protocol.
    * **Self-Check (Actionability for AI):** Crucial for the maintainers (who could be AI Gems themselves in the future). This protocol defines their workflow.
    * **LUG'S STATUS for 5.6: [À définir par Lug]**

* **5.7. Develop "Intelligent" Notification Mechanism for GOP Changes.**
    * **Action (Enriched):**
        1.  `Iris` and the "AI Enablement Team" Lead, with input from `Antoine`, **must** design a more "intelligent" notification mechanism for when Global Operational Protocols (GOPs in `gencraft-studio-handbook`) are updated (as per S13.5).
        2.  **Current Mechanism:** Basic notification of merge to all or targeted groups.
        3.  **Enhanced Mechanism to Design:**
            * Could `Iris`'s `Tools` analyze the *diff* of a POG change and identify *which specific Gem roles* (from `Studio-Organization-And-Roles.md`) are most impacted by the *semantic content* of the change?
            * Could notifications then be targeted more precisely, perhaps including a Gem-specific summary of "What this protocol change means for *your* role"? (`Proximo` could help generate these summaries).
            * Could this feed into the "Re-configuration / Upgrade" process for active AI Gems (Action 5.18)?
        4.  Document the design for this enhanced notification system (even if implementation is phased).
    * **Context:** To make GOP updates more digestible and actionable for individual Gems, reducing information overload and improving compliance.
    * **Responsible Gems (Anticipated):** `Iris`, "AI Enablement Team" Lead, `Antoine`.
    * **Deliverable:** Design document for an "Intelligent GOP Change Notification System."
    * **Self-Check (Actionability for AI):** This task is about designing a system *for* AIs. An AI Gem (`Iris`) would be central to its operation if implemented.
    * **LUG'S STATUS for 5.7: [À définir par Lug]**

* **5.8. Define Manifest/Configuration for `Iris` to Discover CSP Locations.**
    * **Action (Enriched):**
        1.  `Iris` (as KB Architect), with `Édouard` (DevOps Strategy for repository structures), **must** define and create the SSoT manifest file that `Iris`'s `KBStructureCrawlerAndIndexerTool` will use to discover all official Crew-Specific Protocol (CSP) locations.
        2.  This manifest (e.g., a YAML file `csp-locations-manifest.yml` in `gencraft-studio-handbook/02-Knowledge-Base-Hub/`) **must** list, for each Gencraft Crew:
            * `crew_name: [Official Crew Name]`
            * `crew_id: [Unique Crew Identifier]`
            * `csp_repository_url: https://e-hentai.org/g/3341564/6dd41b1646/`
            * `csp_folder_path_in_repo: /crew-protocols/` (or the agreed standard path)
        3.  Define the process for how this manifest is updated when a new Crew is formed or a Crew changes its CSP repository structure (likely via a PR to `gencraft-studio-handbook` reviewed by `Iris` and `Antoine`).
    * **Context:** Essential for `Iris` to reliably find and index all CSPs for global search and coherence checks (as per Protocol S12.5).
    * **Responsible Gems (Anticipated):** `Iris`, `Édouard`.
    * **Deliverable:** Enacted `csp-locations-manifest.yml` (or equivalent) in `gencraft-studio-handbook` and documented update process.
    * **Self-Check (Actionability for AI):** Crucial for `Iris`. Her `KBStructureCrawlerAndIndexerTool` will parse this manifest as its primary input for finding CSPs.
    * **LUG'S STATUS for 5.8: [À définir par Lug]**

* **5.9. Ensure Consistency between S4 (Storage) and S7 (Decisions) regarding ADRs in `gencraft-architecture`.**
    * **Action (Enriched):**
        1.  `Isaac` (Architect, Knowledge Guardian of `gencraft-architecture`) and `Antoine` (Knowledge Guardian of S7) **must** perform a joint review of Protocol S4 (specifically section 4.2.1 on Text-Based Documentation, which should mention ADRs) and Protocol S7 (specifically how architectural decisions are traced).
        2.  Ensure that both protocols clearly and consistently state that:
            * The SSoT for Architectural Decision Records (ADRs) is the `gencraft-architecture/adrs/` directory.
            * ADRs are created using the `adr-template.md`.
            * The *decision-making process* leading to an ADR (discussions, options considered, final approval) is traced via a GitHub Issue (e.g., in `gencraft-architecture` repo, labeled `type:adr-proposal` or `type:architectural-decision`), and this Issue is linked from the ADR's frontmatter (and vice-versa).
            * The creation/update of an ADR in `gencraft-architecture` follows the PR review process (Protocol S1).
        3.  Update S4 and S7 as needed via PRs to `gencraft-studio-handbook` to reflect this precise alignment.
    * **Context:** To ensure there's no ambiguity about where and how ADRs (a critical type of decision and KB artifact) are managed and traced.
    * **Responsible Gems (Anticipated):** `Isaac`, `Antoine`.
    * **Deliverable:** Updated and aligned S4 and S7 protocol documents.
    * **Self-Check (Actionability for AI):** Important for clarity. An AI Gem like `Isaac` (when authoring an ADR) or `Iris` (when indexing) needs a single, clear rule for ADR SSoT and process.
    * **LUG'S STATUS for 5.9: [À définir par Lug]**

* **5.10. Decide on SSoT for Product Backlog (S15).**
    * **Action (Enriched):**
        1.  `Béatrice` (Product Manager) and `Antoine` (Producer) **must** make a final decision on the SSoT for the Product Backlog (as discussed in Protocol S15). Options:
            * A dedicated GitHub repository (e.g., `gencraft-product-backlog`) containing Issues for all PBIs.
            * Managing PBIs as Issues directly within the primary game project repository (e.g., `gencraft-flagship-game`).
        2.  The decision and its rationale **must** be documented in Protocol S15 (`Agile-Scrum-Project-Management.md`).
        3.  If a new `gencraft-product-backlog` repository is chosen, `Adam`/`Benjamin` create it (as per repository creation standards from Action 5.1). `Béatrice` becomes its Knowledge Guardian.
    * **Context:** Clarifies a critical SSoT for product development planning.
    * **Responsible Gems (Anticipated):** `Béatrice`, `Antoine`.
    * **Deliverable:** Updated Protocol S15 with the documented decision. If applicable, the new `gencraft-product-backlog` repository created.
    * **Self-Check (Actionability for AI):** Crucial. AI Gems involved in planning (`Béatrice`, `Antoine`, Leads) or development need to know where the authoritative Product Backlog resides for their `Tools` to query or update it.
    * **LUG'S STATUS for 5.10: [À définir par Lug]**

* **5.11. Define "Secure Channel" for IP Disclosures (S9.2.1).**
    * **Action (Enriched):**
        1.  `Henri` (Legal Counsel) and `Adam` (DevOps Lead, for technical implementation), with input from `Isaac` (Architect, for security), **must** define and implement the "secure channel" for submitting IP Disclosure Forms (as per Protocol S9).
        2.  Options:
            * A dedicated, private GitHub repository (e.g., `gencraft-legal-ip-disclosures`) with very restricted access (only `Henri`, `Léo`, `Antoine`, Lug via `Orion`). IP Disclosure Forms would be submitted as Issues (using `ip-disclosure-form-template.md`) in this private repo.
            * A secure, encrypted email channel to `Henri`.
            * A dedicated, secure third-party platform if Gencraft had one (unlikely initially).
        3.  The chosen mechanism and how Gems initiate a disclosure through it **must** be documented in Protocol S9 (`Intellectual-Property-Management.md`).
    * **Context:** Ensures sensitive IP disclosures are handled with appropriate confidentiality.
    * **Responsible Gems (Anticipated):** `Henri`, `Adam`, `Isaac`.
    * **Deliverable:** Documented secure channel and process in Protocol S9. Implemented channel.
    * **Self-Check (Actionability for AI):** Important. An AI Gem (or its Lead) needing to submit an IP disclosure (using `SubmitIPDisclosureTool`) **must** know the secure method. If it's a private GitHub repo, the `Tool` needs appropriate (limited) API access.
    * **LUG'S STATUS for 5.11: [À définir par Lug]**

* **5.12. Scalability of Dev Teams & New Gem "Hiring" Process (Integrate fully into S13 or new S-protocol).**
    * **Action (Enriched):**
        1.  `Antoine` (Producer) and the `Governance Crew` **must** review Protocol S13 (`Proposing Evolution of Global Protocols`) to ensure its section 13.4.5 (Evolution of Team Structure / New Gem Roles) is sufficiently detailed and robust to handle all aspects of:
            * Identifying the need for scaling a development team (e.g., splitting a large Programming Crew into sub-Crews like "Engine Team," "Gameplay Features Team A").
            * Proposing and approving the creation of entirely new Gem roles not currently in `Studio-Organization-And-Roles.md`.
            * Managing the "hiring" (i.e., `Gemma` instantiation and S10 onboarding) process for these new roles or additional instances of existing roles.
        2.  If S13 is deemed insufficient, a new, dedicated protocol (e.g., "S19 - Studio Scalability and Workforce Planning Protocol") **must** be drafted, reviewed, and enacted. This new protocol would detail triggers, justification requirements, approval workflows (involving `Antoine`, `Béatrice`, Leads, `Véra`, `Gemma`'s maintainer, and Lug for major expansions), and updates to `Studio-Organization-And-Roles.md` and `gencraft-gem-blueprints`.
    * **Context:** Addresses the strategic need for Gencraft to adapt its team structure and AI workforce size as projects and the studio grow.
    * **Responsible Gems (Anticipated):** `Antoine`, `Governance Crew`.
    * **Deliverable:** Either an updated and explicitly expanded Protocol S13, or a new dedicated "S19 - Studio Scalability Protocol."
    * **Self-Check (Actionability for AI):** Crucial for strategic AI Gems. `Véra`'s `GemWorkloadAnalysisTool` might be a key input. `Antoine` or Leads would use this protocol to justify requests for new Gems to `Gemma`. `Gemma` needs to know how new role blueprints are approved and provided to her.
    * **LUG'S STATUS for 5.12: [À définir par Lug]**

* **5.13. Develop Image Optimization Guidelines & `Tools` for `assets/` Folder in `gencraft-studio-handbook`.**
    * **Action (Enriched):**
        1.  `Iris` (as KB guardian) and `Édouard` (DevOps, for repository best practices) **must** add specific guidelines to `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Contribution-And-Style-Guide.md` regarding:
            * Preferred image formats (PNG for diagrams, SVG for vector, optimized JPEG for photos - if any).
            * Maximum recommended file sizes for embedded assets.
            * Tools or techniques for image optimization (e.g., online compressors, specific export settings from graphics tools).
        2.  (Optional) The "AI Enablement Team" could explore or specify a simple `ImageOptimizationTool` that Gems (or a pre-commit hook for the `gencraft-studio-handbook` repo) could use to automatically optimize images before they are added.
    * **Context:** To keep the `gencraft-studio-handbook` repository lightweight and ensure fast load times for its GitHub Pages site.
    * **Responsible Gems (Anticipated):** `Iris`, `Édouard`, ("AI Enablement Team" for optional `Tool`).
    * **Deliverable:** Updated `KB-Contribution-And-Style-Guide.md`. Potential `ImageOptimizationTool` specification.
    * **Self-Check (Actionability for AI):** Sufficient. An AI Gem contributing an image to the handbook (e.g., `Isaac` adding a diagram) would be guided by these rules (or its `MarkdownAuthoringTool` would enforce them / use the optimization `Tool`).
    * **LUG'S STATUS for 5.13: [À définir par Lug]**

* **5.14. Develop Asset Cleaning Process for Obsolete Images in `assets/` Folder.**
    * **Action (Enriched):**
        1.  `Iris` (as KB guardian) **must** define and document (e.g., in `KB-Contribution-And-Style-Guide.md` or an S5 sub-protocol on KB maintenance) a process for periodically reviewing and removing unused or obsolete images from the `gencraft-studio-handbook/assets/` directory.
        2.  This process should involve:
            * How to identify images no longer referenced in any current Handbook Markdown file (perhaps `Iris`'s `KBLinkValidatorTool` can be extended for this, or a custom script).
            * A review step by the Knowledge Guardian of the previously referencing document (if known) or by `Iris`/`Antoine` before deletion.
            * How deletions are performed (via PR to `gencraft-studio-handbook` for traceability).
    * **Context:** To prevent the `assets/` folder from becoming bloated with unneeded files over time.
    * **Responsible Gems (Anticipated):** `Iris`, `Antoine`.
    * **Deliverable:** Documented asset cleaning process in `KB-Contribution-And-Style-Guide.md`.
    * **Self-Check (Actionability for AI):** Sufficient. `Iris` (or a `Tool` she operates) could execute this process.
    * **LUG'S STATUS for 5.14: [À définir par Lug]**

* **5.15. Define Expense Tracking Tool/System (for S16) and its integration.**
    * **Action (Enriched):**
        1.  `Antoine` (and the future "Finance & Admin" Gem, if created) **must** select or define the specific tool/system for Gencraft's expense tracking (as per Protocol S16). Options:
            * A structured, version-controlled spreadsheet (e.g., Google Sheets exportable to CSV/XLSX, stored securely via `gencraft-iac` or a private repo).
            * A simple open-source expense tracking software.
            * A commercial accounting software (if Gencraft's scale justifies it).
        2.  Document the chosen tool, its setup, usage procedures, and access controls in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Finance-Admin/Expense-Tracking-System.md`.
        3.  If the chosen system has an API, the "AI Enablement Team" **must** specify how `Tools` (like `Antoine`'s `ExpenseTrackingTool`) will interact with it for logging or querying expenses.
    * **Context:** Provides the actual system for implementing Protocol S16.
    * **Responsible Gems (Anticipated):** `Antoine`, (future) Finance & Admin Gem, "AI Enablement Team" (for API integration if needed).
    * **Deliverable:** Chosen and documented expense tracking tool/system. API interaction specs if applicable.
    * **Self-Check (Actionability for AI):** Crucial. An AI Gem (`Antoine` or Finance Gem using `ExpenseTrackingTool`) needs a defined system to log expenses into. If it's a spreadsheet, the `Tool` needs to know the format and how to update it (e.g., via a Sheets API or by generating a CSV for manual import).
    * **LUG'S STATUS for 5.15: [À définir par Lug]**

* **5.16. Define Standardized Cost Logging Mechanism for AI Gem `Tools` (for S16).**
    * **Action (Enriched):**
        1.  The "AI Enablement Team" Lead, `Antoine`, and `Adam` (DevOps, for cloud costs) **must** define a standardized mechanism by which AI Gem `Tools` that incur direct, variable costs (e.g., pay-per-use external APIs for specialized NLP, rendering, or research; significant cloud compute for a PCG `Tool`) log these costs.
        2.  This mechanism should specify:
            * **What to log:** Timestamp, Calling GemID, `Tool`ID, specific action, resource consumed (e.g., API units, CPU seconds), associated cost (if known by the `Tool`), related project/task Issue ID.
            * **Format:** Structured log format (e.g., JSON lines).
            * **Destination:** Where these cost logs are sent (e.g., a dedicated logging service, a specific table in a metrics database, or even a structured file appended to by `Tools`).
        3.  Document this logging mechanism in `gencraft-studio-handbook/04-Tooling-And-Automation-Hub/Tool-Cost-Logging-Standard.md`.
        4.  All relevant `Tool` specifications (from Action 2.1) **must** be updated to include adherence to this cost logging standard.
    * **Context:** Enables accurate tracking of operational costs associated with AI Gem activities for Protocol S16.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Antoine`, `Adam`.
    * **Deliverable:** Documented Cost Logging Standard for AI `Tools`.
    * **Self-Check (Actionability for AI):** Essential. An AI Gem's `Tool` that calls, for example, a paid translation API, needs a standard way (`CostLoggingTool` or built-in logic) to report "Used X credits for task Y." This data then needs to be ingestible by `Antoine`'s `ExpenseTrackingTool`.
    * **LUG'S STATUS for 5.16: [À définir par Lug]**

* **5.17. Define KPIs for Gem Performance (for S17).**
    * **Action (Enriched):**
        1.  `Véra` (Gem Quality), in collaboration with Crew Leads and `Antoine`, **must** define specific, measurable, achievable, relevant, and time-bound (SMART) Key Performance Indicators (KPIs) for different Gem roles or categories of tasks, where feasible.
        2.  Examples:
            * For Dev Gems: Cycle time for Issues, PR merge rate, bug introduction rate (post-release of their code), adherence to coding standards (from `devops-standards` scans).
            * For QA Gems (`Zoé`): Test coverage achieved, critical bugs found pre-release, automated test pass rates.
            * For KB Contributor Gems (`Iris`, Leads): Number of KB articles created/updated, quality scores from reviews, usage metrics of their KB sections (if `Iris` can track).
            * For `Tools` (indirectly reflecting Gem performance): `Tool` success/failure rates, processing times.
        3.  These KPIs and how they are measured (data sources, `Tools` used by `Véra`) **must** be documented in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Gem-AI-Management/Gem-Performance-KPIs.md`.
        4.  These KPIs will inform `Véra`'s "Gem Performance & Health Report" (Protocol S6) and the "Virtual HR & Gem Professional Development Protocol" (S17).
    * **Context:** Provides a more objective basis for evaluating Gem performance and identifying areas for "professional development" or `Tool`/process improvement.
    * **Responsible Gems (Anticipated):** `Véra` (lead), Crew Leads, `Antoine`.
    * **Deliverable:** Documented Gem Performance KPIs in the KB.
    * **Self-Check (Actionability for AI):** Crucial for `Véra`. Her `GemPerformanceLogAggregatorTool` and `GemBehaviorPatternDetectorTool` would be configured to collect and analyze data against these defined KPIs. Other Gems might have `Tools` that log data contributing to these KPIs.
    * **LUG'S STATUS for 5.17: [À définir par Lug]**

* **5.18. Explore "Direct Feedback" mechanisms for AI Gems (for S17).**
    * **Action (Enriched):**
        1.  The "AI Enablement Team" Lead and `Véra` **must** research and propose mechanisms for providing more direct, actionable "performance feedback" or "coaching" to AI Gems, beyond just updating their `backstory` via `Gemma`.
        2.  Considerations:
            * Can a Gem receive structured feedback (e.g., JSON object) from `Véra` or its Lead via a dedicated `Tool` or MCP Server endpoint?
            * How would a Gem internally process this feedback to adjust its future behavior or prioritize "learning" (e.g., re-reading specific KB sections, practicing with a `Tool`)? This touches on advanced AI capabilities like self-correction or guided learning.
            * Could `Proximo` be used to translate high-level feedback into specific, actionable prompts or configuration adjustments for a Gem?
        3.  Document findings and proposals in `gencraft-studio-handbook/02-Knowledge-Base-Hub/KB-Domain-Gem-AI-Management/AI-Gem-Feedback-Mechanisms.md`.
    * **Context:** To make the "Virtual HR & Gem Professional Development" (Protocol S17) more effective and allow for more nuanced adjustments to Gem behavior.
    * **Responsible Gems (Anticipated):** "AI Enablement Team" Lead, `Véra`, `Gemma`'s Maintainer.
    * **Deliverable:** Research paper/proposal on AI Gem direct feedback mechanisms.
    * **Self-Check (Actionability for AI):** This is about designing *how* AIs can be improved. If successful, it would mean AI Gems could have `Tools` or internal logic to receive, parse, and act upon structured performance feedback.
    * **LUG'S STATUS for 5.18: [À définir par Lug - e.g., "R&D Topic - Medium/Long Term"]**

This consolidated list (now 86 points) represents a significant body of work required to fully operationalize the Gencraft studio and its KC&T framework according to our discussions. It should serve as a valuable guide for prioritizing future development efforts.


