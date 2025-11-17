#!/usr/bin/env python3
"""Very small YAML parser for onboarding helpers."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, List, Tuple


def _strip_comments(line: str) -> str:
    in_single = False
    in_double = False
    result_chars: List[str] = []
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            if i > 0 and line[i - 1] == '\\':
                pass
            else:
                in_double = not in_double
        if ch == '#' and not in_single and not in_double:
            break
        result_chars.append(ch)
        i += 1
    return ''.join(result_chars).rstrip()


def _parse_scalar(token: str) -> Any:
    token = token.strip()
    if token in {"null", "Null", "NULL", "~"}:
        return None
    if token in {"true", "True"}:
        return True
    if token in {"false", "False"}:
        return False
    if token.startswith('"') and token.endswith('"') and len(token) >= 2:
        return token[1:-1]
    if token.startswith("'") and token.endswith("'") and len(token) >= 2:
        return token[1:-1]
    return token


def _split_key_value(line: str) -> Tuple[str, str]:
    if ':' not in line:
        return line.strip(), ''
    key, value = line.split(':', 1)
    return key.strip(), value.strip()


@dataclass
class SimpleYAMLParser:
    text: str

    def __post_init__(self) -> None:
        processed: List[str] = []
        for raw_line in self.text.splitlines():
            trimmed = _strip_comments(raw_line.rstrip('\n'))
            if not trimmed:
                continue
            stripped = trimmed.strip()
            if stripped in {'---', '...'}:
                continue
            processed.append(trimmed)
        self.lines: List[str] = processed
        self.index: int = 0

    def parse(self) -> Any:
        result = self._parse_value(0)
        return result if result is not None else {}

    def _indent(self, line: str) -> int:
        return len(line) - len(line.lstrip(' '))

    def _parse_value(self, indent: int) -> Any:
        while self.index < len(self.lines):
            line = self.lines[self.index]
            stripped = line.strip()
            if not stripped:
                self.index += 1
                continue
            current_indent = self._indent(line)
            if current_indent < indent:
                return None
            if stripped.startswith('- '):
                return self._parse_list(indent)
            return self._parse_mapping(indent)
        return None

    def _parse_list(self, indent: int) -> List[Any]:
        items: List[Any] = []
        while self.index < len(self.lines):
            line = self.lines[self.index]
            stripped = line.strip()
            current_indent = self._indent(line)
            if current_indent < indent or not stripped.startswith('- '):
                break
            item_body = stripped[2:].strip()
            if not item_body:
                self.index += 1
                items.append(self._parse_value(indent + 2))
                continue
            if ':' in item_body:
                item_dict = {}
                key, value_part = _split_key_value(item_body)
                if value_part == '':
                    self.index += 1
                    item_dict[key] = self._parse_value(indent + 2)
                else:
                    item_dict[key] = _parse_scalar(value_part)
                    self.index += 1
                while self.index < len(self.lines):
                    next_line = self.lines[self.index]
                    next_indent = self._indent(next_line)
                    if next_indent < indent + 2:
                        break
                    next_stripped = next_line.strip()
                    if next_stripped.startswith('- '):
                        break
                    key2, value_part2 = _split_key_value(next_stripped)
                    if value_part2 == '':
                        self.index += 1
                        item_dict[key2] = self._parse_value(next_indent + 2)
                    else:
                        item_dict[key2] = _parse_scalar(value_part2)
                        self.index += 1
                items.append(item_dict)
            else:
                items.append(_parse_scalar(item_body))
                self.index += 1
        return items

    def _parse_mapping(self, indent: int) -> Any:
        mapping = {}
        while self.index < len(self.lines):
            line = self.lines[self.index]
            stripped = line.strip()
            current_indent = self._indent(line)
            if current_indent < indent:
                break
            if stripped.startswith('- '):
                break
            if ':' not in stripped:
                self.index += 1
                continue
            key, value_part = _split_key_value(stripped)
            if value_part == '':
                self.index += 1
                mapping[key] = self._parse_value(current_indent + 2)
            else:
                mapping[key] = _parse_scalar(value_part)
                self.index += 1
        return mapping


def load_yaml_string(content: str) -> Any:
    parser = SimpleYAMLParser(content)
    return parser.parse()
