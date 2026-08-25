#!/usr/bin/env python3
# Purpose:      Sweep the GenCr@ft workspace side-by-side repositories and automatically align
#               AGENTS.md and CLAUDE.md files with the strict Traceability Protocol branch
#               naming standard and the co-author trailer prohibition.
# Author(s):    Gem-BB (Camille)
# Creation Date: 2026-05-24
# Version:      1.3.0

import os
import re
from pathlib import Path

WORKSPACE_DIR = Path(os.environ.get("GFT_WORKSPACE_DIR", str(Path.home() / "gft_studio"))).resolve()

# Directories to skip entirely
SKIP_DIRS = {
    ".git",
    ".remember",
    ".planning",
    ".keys",
    ".claude",
    ".antigravitycli",
    ".github",
    ".github-private",
    "Godot_v4.5-stable_linux.x86_64",
    "Godot_v4.2-stable_linux.x86_64",
    "senior expertise",
    "docs",
    "wt-gut",
    "wt-jest-nestjs",
    "wt-jest-ts",
    "wt-nestjs-hexarch",
    "wt-pytest",
    "test-results",
}


def sync_agents_md(agents_file: Path) -> bool:
    """Updates AGENTS.md with aligned branch naming and co-author constraints using regex/string replacement."""
    try:
        content = agents_file.read_text(encoding="utf-8")
        original_content = content

        # 1. Update Branch Naming & Conventions
        content = re.sub(
            r"Branch(?: naming)?:\s*`feat/`,\s*`fix/`,\s*`(?:docs|test)/`,\s*`chore/`.*?(?=\n|$)",
            r"Branch: Conforms strictly to `feat/issue-ID-slug` and `fix/issue-ID-slug` branch naming standard (e.g., `feat/issue-104-inventory-service`).",
            content,
        )

        # 2. Update WI Title formats if present
        content = re.sub(
            r"Title:\s*`feat\([^)]+\):\s*WI-X\.Y\s*—\s*description`.*?(?=\n|$)",
            r"Title: `feat(scope): issue-ID-slug — description`.",
            content,
        )

        # 3. Update Co-author trailer prohibition
        content = re.sub(
            r"- AI commits:\s*`Co-Authored-By: Claude Sonnet 4\.6 <noreply@anthropic\.com>`",
            r"- Co-author trailer: Strictly prohibited in this workspace due to administrative blocks. Do NOT write or push commits containing the `Co-Authored-By` trailer.",
            content,
        )

        # Fallback raw string replacements for safety
        replacements = {
            "Branch naming: `docs/`, `feat/`, `fix/`, `chore/`": "Branch: Conforms strictly to `feat/issue-ID-slug` and `fix/issue-ID-slug` branch naming standard (e.g., `feat/issue-104-inventory-service`)",
            "Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>": "Strictly prohibited in this workspace due to administrative blocks. Do NOT write or push commits containing the `Co-Authored-By` trailer.",
        }
        for old, new in replacements.items():
            content = content.replace(old, new)

        if content != original_content:
            agents_file.write_text(content, encoding="utf-8")
            return True

        return False
    except Exception as e:
        print(f"Error processing {agents_file}: {e}")
        return False


def sync_claude_md(claude_file: Path) -> bool:
    """Updates CLAUDE.md with aligned branch naming and co-author constraints."""
    try:
        content = claude_file.read_text(encoding="utf-8")
        original_content = content

        # Replace branch naming patterns
        content = re.sub(
            r"- \*\*Branch naming:\*\* `feat/`,\s*`fix/`,\s*`docs/`,\s*`test/`,\s*`chore/`,\s*`refactor/`.*?(?=\n|$)",
            r"- **Branch naming:** Conforms strictly to `feat/issue-ID-slug` and `fix/issue-ID-slug` branch naming standard (e.g., `feat/issue-104-inventory-service`).",
            content,
        )

        # Replace co-author block
        content = re.sub(
            r"- \*\*Co-author trailer\*\* on all AI-generated commits:\s*```\s*Co-Authored-By: Claude Sonnet 4\.6 <noreply@anthropic\.com>\s*```",
            r"- **Co-author trailer:** Strictly prohibited in this workspace due to administrative blocks. Do NOT write or push commits containing the `Co-Authored-By` trailer.",
            content,
            flags=re.DOTALL,
        )

        # Fallback raw string replacements
        replacements = {
            "Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>": "Strictly prohibited in this workspace due to administrative blocks. Do NOT write or push commits containing the `Co-Authored-By` trailer."
        }
        for old, new in replacements.items():
            content = content.replace(old, new)

        if content != original_content:
            claude_file.write_text(content, encoding="utf-8")
            return True

        return False
    except Exception as e:
        print(f"Error processing {claude_file}: {e}")
        return False


def main():
    print(f"Starting onboarding manuals sync inside workspace: {WORKSPACE_DIR}")

    updated_agents = 0
    updated_claudes = 0
    total_repos = 0

    for item in WORKSPACE_DIR.iterdir():
        if item.is_dir() and item.name not in SKIP_DIRS:
            total_repos += 1
            agents_file = item / "AGENTS.md"
            claude_file = item / "CLAUDE.md"

            if agents_file.exists():
                if sync_agents_md(agents_file):
                    print(f"  [OK] Updated AGENTS.md in {item.name}")
                    updated_agents += 1

            if claude_file.exists():
                if sync_claude_md(claude_file):
                    print(f"  [OK] Updated CLAUDE.md in {item.name}")
                    updated_claudes += 1

    print("\n--- Synchronization Report ---")
    print(f"Total repositories scanned: {total_repos}")
    print(f"AGENTS.md files updated:     {updated_agents}")
    print(f"CLAUDE.md files updated:     {updated_claudes}")
    print("Done!")


if __name__ == "__main__":
    main()
