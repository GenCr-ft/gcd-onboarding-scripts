#!/usr/bin/env python3
"""Parse ENV_VARIABLES_STANDARD.md and print env assignments."""

import os
import re
import sys
from pathlib import Path

ROLE_ARG_ERROR = "Usage: get_standard_env_vars.py <role-name>"


def normalize_role(name: str) -> str:
    slug = re.sub(r"[^a-z0-9_-]+", "-", name.strip().lower()).strip("-")
    return slug


def load_sections(md_path: Path):
    data = {"common": [], "roles": {}}
    current_target = None
    collecting = False

    if not md_path.is_file():
        raise FileNotFoundError(f"Missing env spec file: {md_path}")

    with md_path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\n")
            stripped = line.strip()

            if stripped.startswith("## ") and not stripped.startswith("###"):
                heading = stripped[3:].strip()
                if "common" in heading.lower():
                    current_target = ("common", None)
                else:
                    current_target = None
                collecting = False
                continue

            if stripped.startswith("### "):
                role_key = normalize_role(stripped[4:])
                current_target = ("role", role_key)
                collecting = False
                continue

            if stripped.startswith("```"):
                fence_lang = stripped.strip("`").lower()
                if collecting:
                    collecting = False
                else:
                    collecting = fence_lang in {"env", "bash"}
                continue

            if (
                collecting
                and current_target
                and stripped
                and not stripped.startswith("#")
            ):
                if current_target[0] == "common":
                    data["common"].append(stripped)
                elif current_target[0] == "role":
                    data["roles"].setdefault(current_target[1], []).append(stripped)

    return data


def main():
    if len(sys.argv) < 2:
        print(ROLE_ARG_ERROR, file=sys.stderr)
        sys.exit(1)

    role_name = normalize_role(sys.argv[1])

    if len(sys.argv) >= 3:
        md_path = Path(sys.argv[2])
    else:
        ssot_path = os.environ.get("GFT_SSOT_PATH")
        if not ssot_path:
            print("GFT_SSOT_PATH is not defined.", file=sys.stderr)
            sys.exit(1)
        md_path = Path(ssot_path) / "tooling" / "ENV_VARIABLES_STANDARD.md"

    sections = load_sections(md_path)

    for line in sections["common"]:
        print(line)

    for line in sections["roles"].get(role_name, []):
        print(line)


if __name__ == "__main__":
    main()
