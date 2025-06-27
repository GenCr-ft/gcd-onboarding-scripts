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
import yaml

def get_all_tools_for_role(matrix_data, role_name):
    all_tools = set()
    try:
        roles_map = {role['name']: role for role in matrix_data.get('roles', [])}
    except (TypeError, KeyError):
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
            continue

        current_role_data = roles_map[current_role_name]

        if 'tools' in current_role_data and current_role_data['tools'] is not None:
            for tool in current_role_data['tools']:
                all_tools.add(tool)

        parent_role = current_role_data.get('inherits')
        if parent_role:
            roles_to_process.append(parent_role)

    return sorted(list(all_tools))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)

    target_role = sys.argv[1]

    try:
        yaml_data = yaml.safe_load(sys.stdin)
        if not yaml_data:
            sys.exit(1)
    except yaml.YAMLError:
        sys.exit(1)

    tools = get_all_tools_for_role(yaml_data, target_role)
    for tool in tools:
        print(tool)
