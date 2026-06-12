#!/usr/bin/env python3
#
# ID: GFT_PYTHON_HELPER_GET_ROLE_REPOS
# Title: Python Helper - Role Repository Inheritance Resolver
# Author(s): Gem-BB (Camille)
# Creation Date: 2025-06-26
# Last Modified Date: 2025-06-26
# Version: 1.0.0
#
# Description:
#   This script is a helper called by the main onboarding script. It receives
#   YAML data from the Role-Tooling Matrix via stdin and a target role name
#   as an argument. It recursively traverses the inheritance chain ('inherits')
#   and prints a deduplicated, sorted list of all required repositories for that
#   role to stdout.
#
# Usage:
#   echo "$YAML_DATA" | ./get_role_repos.py <role_name>
#
# Dependencies:
#   - Python 3.9+
#   - PyYAML library

import sys

from simple_yaml import load_yaml_string


def gather_default_repositories(matrix_data, roles_map):
    """Return repositories defined as defaults in the matrix."""

    default_repos = set()

    if not isinstance(matrix_data, dict):
        return default_repos

    for repo in matrix_data.get("default_repositories") or []:
        if repo:
            default_repos.add(repo)

    common_base = roles_map.get("common-base")
    if common_base:
        for repo in common_base.get("repositories") or []:
            if repo:
                default_repos.add(repo)

    return default_repos


def get_all_repos_for_role(matrix_data, role_name):
    all_repos = set()
    try:
        roles_map = {role["name"]: role for role in matrix_data.get("roles", [])}
    except (TypeError, KeyError, AttributeError):
        return []

    base_repos = gather_default_repositories(matrix_data, roles_map)
    all_repos.update(base_repos)

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

        repositories = current_role_data.get("repositories") or []
        for repo in repositories:
            if repo:
                all_repos.add(repo)

        parent_role = current_role_data.get("inherits")
        if parent_role:
            roles_to_process.append(parent_role)

    return sorted(list(all_repos))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(1)

    target_role = sys.argv[1]

    yaml_content = sys.stdin.read()
    yaml_data = load_yaml_string(yaml_content)
    if not yaml_data:
        sys.exit(1)

    repos = get_all_repos_for_role(yaml_data, target_role)
    for repo in repos:
        print(repo)
