#!/usr/bin/env python3
"""Catch missing Chinese option help when upstream adds settings, on all platforms."""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
menu = (root / 'src/btop_menu.cpp').read_text()
categories = menu.split('const vector<vector<vector<string>>> categories = {', 1)[1].split('msgBox::msgBox()', 1)[0]
expected = set(re.findall(r'\{\s*"([a-z_0-9]+)"', categories))
translations = (root / 'src/btop_options_zh.hpp').read_text()
entries = re.findall(r'\{"([a-z_0-9]+)",\s*\{([^\n]+)\}\}', translations)
actual = {key for key, value in entries if re.search(r'[\u4e00-\u9fff]', value)}
assert len(entries) == len(actual), 'Duplicate or non-Chinese descriptions'
assert expected == actual, f'Missing: {sorted(expected - actual)}; obsolete: {sorted(actual - expected)}'
print(f'PASS: Chinese descriptions cover all {len(expected)} options, including conditional platform options')
