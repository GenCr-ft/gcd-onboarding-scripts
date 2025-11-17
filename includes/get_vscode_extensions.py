#!/usr/bin/env python3
"""Parse VSCODE_RECOMMENDATIONS.md and print extension identifiers."""
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

ROLE_ARG_ERROR = "Usage: get_vscode_extensions.py <role-name>"


def normalize_role(name: str) -> str:
    return re.sub(r"[^a-z0-9_-]+", "-", name.strip().lower()).strip("-")


def load_lists(md_path: Path):
    global_exts = []
    role_exts = defaultdict(list)
    current_scope = None

    if not md_path.is_file():
        raise FileNotFoundError(f"Missing VS Code spec file: {md_path}")

    with md_path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            stripped = raw_line.strip()
            if stripped.startswith("## ") and not stripped.startswith("###"):
                heading = stripped[3:].strip().lower()
                if "global" in heading:
                    current_scope = ("global", None)
                else:
                    current_scope = None
                continue

            if stripped.startswith("### "):
                current_scope = ("role", normalize_role(stripped[4:]))
                continue

            if stripped.startswith("-"):
                extension_id = stripped[1:].strip()
                if not extension_id:
                    continue
                if current_scope == ("global", None):
                    global_exts.append(extension_id)
                elif current_scope and current_scope[0] == "role":
                    role_exts[current_scope[1]].append(extension_id)

    return global_exts, role_exts


def main():
    if len(sys.argv) != 2:
        print(ROLE_ARG_ERROR, file=sys.stderr)
        sys.exit(1)

    role_name = normalize_role(sys.argv[1])
    ssot_path = os.environ.get("GFT_SSOT_PATH")
    if not ssot_path:
        print("GFT_SSOT_PATH is not defined.", file=sys.stderr)
        sys.exit(1)

    md_path = Path(ssot_path) / "tooling" / "VSCODE_RECOMMENDATIONS.md"
    global_exts, role_exts = load_lists(md_path)

    for ext in global_exts:
        print(ext)

    for ext in role_exts.get(role_name, []):
        print(ext)


if __name__ == "__main__":
    main()
