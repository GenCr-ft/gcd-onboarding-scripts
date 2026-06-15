#!/usr/bin/env python3
#
# ID: GFT_PYTHON_HELPER_GET_ROLE_TOOLS
# Title: Python Helper - Role Tool Inheritance Resolver
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-11
# Last Modified Date: 2025-06-27
# Version: 1.3.0 (Robust Queue-based implementation)
#
# Description:
#   This script correctly resolves the entire inheritance chain for a given role
#   and returns a complete, deduplicated list of required tools.
#
# Usage:
#   echo "$YAML_DATA" | ./get_role_tools.py <role_name>

import sys

from simple_yaml import load_yaml_string


def get_all_tools_for_role(matrix_data, role_name):
    """
    Recursively traverses the inheritance chain to aggregate all tools
    for a given role and its parents.
    """
    all_tools = set()
    try:
        roles_map = {role["name"]: role for role in matrix_data.get("roles", [])}
    except (TypeError, KeyError) as e:
        print(
            f"Error: Formatting error in the 'roles' section of the YAML: {e}",
            file=sys.stderr,
        )
        return []

    # Use a queue for robust, level-by-level traversal of the inheritance tree
    roles_to_process = [role_name]
    visited_roles = set()

    while roles_to_process:
        current_role_name = roles_to_process.pop(0)
        if current_role_name in visited_roles:
            continue

        visited_roles.add(current_role_name)

        if current_role_name not in roles_map:
            print(
                f"::warning:: Role '{current_role_name}' found in an 'inherits' key but is not defined in the roles list. Inheritance chain is broken.",
                file=sys.stderr,
            )
            continue

        current_role_data = roles_map[current_role_name]

        if "tools" in current_role_data and current_role_data["tools"] is not None:
            tools_value = current_role_data["tools"]
            if isinstance(tools_value, str):
                import json as _json
                try:
                    tools_value = _json.loads(tools_value)
                except (ValueError, TypeError):
                    tools_value = [tools_value]
            for tool in tools_value:
                if isinstance(tool, dict):
                    tool_name = tool.get("name") or tool.get("id") or ""
                    if tool_name:
                        all_tools.add(str(tool_name))
                elif tool is not None:
                    all_tools.add(str(tool))

        parent_role = current_role_data.get("inherits")
        if parent_role:
            roles_to_process.append(parent_role)

    return sorted(list(all_tools))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <role_name>", file=sys.stderr)
        sys.exit(1)

    target_role = sys.argv[1]

    yaml_content = sys.stdin.read()
    yaml_data = load_yaml_string(yaml_content)
    if not yaml_data:
        sys.exit(1)

    tools = get_all_tools_for_role(yaml_data, target_role)
    for tool in tools:
        print(tool)
