#!/usr/bin/env python3
"""Checks the stdout of s22_example.lua and prints its CHECK line (simlib's TAB-separated format), which suite.sh
appends to the scenario's results file: s22_example.py <results file> <stdout log>.
Checks:
  log   the Simulator's stdout has no plugin warning and no Lua runtime error
"""
import sys
from pathlib import Path

# The trailing colon keeps out Solar2D's "WARNING: plugin.spine43 is not configured in build.settings" line.
LOG_ERRORS = ("WARNING: plugin.spine:", "Runtime error")

lines = Path(sys.argv[2]).read_text(errors="replace").splitlines()
bad = [line for line in lines if any(e in line for e in LOG_ERRORS)]
print("CHECK\t%s\tlog\t%s" % ("FAIL" if bad else "PASS", " | ".join(bad[:3])))
