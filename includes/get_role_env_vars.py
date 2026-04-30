#!/usr/bin/env python3
#
# ID: GFT_PYTHON_HELPER_GET_ROLE_ENV_VARS
# Title: Python Helper - Role Environment Variable Inheritance Resolver
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-27
# Version: 1.0.1
#
# Description:
#   This script receives YAML data from the Role-Tooling Matrix via stdin
#   and a target role name as an argument. It recursively traverses the
#   inheritance chain and prints a deduplicated list of environment
#   variables for that role to stdout, formatted as KEY="VALUE".
#
# Usage:
#   echo "$YAML_DATA" | ./get_role_env_vars.py <role_name>

import sys
import os

# Add the parent directory to sys.path so we can import simple_yaml
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from simple_yaml import load_yaml_string

def get_all_env_vars_for_role(matrix_data, role_name):
    """
    Recursively finds all environment variables for a given role.
    It returns a dictionary to handle overrides correctly.
    """
    final_vars = {}
    visited_roles = set()

    # First, build the full inheritance chain
    inheritance_chain = []
    current_role = role_name
    roles_map = {role['name']: role for role in matrix_data.get('roles', [])}

    while current_role and current_role not in visited_roles:
        inheritance_chain.append(current_role)
        visited_roles.add(current_role)
        current_role = roles_map.get(current_role, {}).get('inherits')

    # Apply variables from parent to child, allowing overrides
    for role in reversed(inheritance_chain):
        role_data = roles_map.get(role, {})
        if 'environment_variables' in role_data and role_data['environment_variables'] is not None:
            final_vars.update(role_data['environment_variables'])

    return final_vars

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)

    target_role = sys.argv[1]

    try:
        raw_input = sys.stdin.read()
        yaml_data = load_yaml_string(raw_input)
        if not yaml_data:
            print("Error: Received empty input or invalid YAML.", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error parsing YAML: {e}", file=sys.stderr)
        sys.exit(1)

    env_vars = get_all_env_vars_for_role(yaml_data, target_role)
    for key, value in env_vars.items():
        # Print in KEY="VALUE" format for easy parsing in Bash
        print(f'{key}="{value}"')
