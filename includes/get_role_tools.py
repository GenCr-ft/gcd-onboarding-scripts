#!/usr/bin/env python3
#
# ID: GFT_PYTHON_HELPER_GET_ROLE_TOOLS
# Title: Python Helper - Role Tool Inheritance Resolver
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-11
# Last Modified Date: 2025-06-26
# Version: 1.2.0
#
# Description:
#   This script is a helper called by the main onboarding script. It receives
#   YAML data from the Role-Tooling Matrix via stdin and a target role name
#   as an argument. It recursively traverses the inheritance chain ('inherits')
#   and prints a deduplicated, sorted list of all required tools for that
#   role to stdout.
#
# Usage:
#   echo "$YAML_DATA" | ./get_role_tools.py <role_name>
#
# Dependencies:
#   - Python 3.9+
#   - PyYAML library

import sys
import yaml

def get_all_tools_for_role(matrix_data, role_name):
    """
    Recursively traverses the inheritance chain to aggregate all tools
    for a given role and its parents.

    Args:
        matrix_data (dict): The full YAML content of the role matrix.
        role_name (str): The name of the starting role.

    Returns:
        list: A sorted and deduplicated list of all required tools.
    """
    all_tools = set()

    # Create a dictionary for quick access to role data by name.
    try:
        roles_map = {role['name']: role for role in matrix_data.get('roles', [])}
    except (TypeError, KeyError) as e:
        print(f"Error: Formatting error in the 'roles' section of the YAML: {e}", file=sys.stderr)
        return []

    # Use a queue to manage the traversal, starting with the target role.
    roles_to_process = [role_name]

    # Use a set to guard against infinite inheritance loops.
    visited_roles = set()

    while roles_to_process:
        current_role_name = roles_to_process.pop(0)

        if current_role_name in visited_roles:
            continue # Already processed, skip to avoid loops.

        visited_roles.add(current_role_name)

        # Check if the role exists in our map.
        if current_role_name not in roles_map:
            print(f"::warning:: Role '{current_role_name}' found in an 'inherits' key but is not defined in the roles list. Inheritance chain is broken.", file=sys.stderr)
            continue

        current_role_data = roles_map[current_role_name]

        # Add tools from the current role.
        # The `is not None` check is important for roles that have no tools.
        if 'tools' in current_role_data and current_role_data['tools'] is not None:
            for tool in current_role_data['tools']:
                all_tools.add(tool)

        # Add the parent role to the queue for the next iteration.
        parent_role = current_role_data.get('inherits')
        if parent_role:
            roles_to_process.append(parent_role)

    # The "common-base" role is an implicit and universal dependency.
    # We ensure its tools are included, even if the inheritance chain was broken.
    if 'common-base' in roles_map and 'common-base' not in visited_roles:
         if 'tools' in roles_map['common-base'] and roles_map['common-base']['tools'] is not None:
            for tool in roles_map['common-base']['tools']:
                all_tools.add(tool)

    return sorted(list(all_tools))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <role_name>", file=sys.stderr)
        sys.exit(1)

    target_role = sys.argv[1]

    try:
        yaml_data = yaml.safe_load(sys.stdin)
        if not yaml_data:
            print("Error: No YAML data received from stdin.", file=sys.stderr)
            sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error parsing YAML from stdin: {e}", file=sys.stderr)
        sys.exit(1)

    tools = get_all_tools_for_role(yaml_data, target_role)
    for tool in tools:
        print(tool)
