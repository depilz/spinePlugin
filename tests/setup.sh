#!/bin/bash
# One-time setup of a clone: points git at the tracked hooks in .githooks/ (the pre-push hook runs the default test run).
set -euo pipefail

git -C "$(dirname "$0")/.." config core.hooksPath .githooks
echo "setup.sh: core.hooksPath = $(git -C "$(dirname "$0")/.." config --get core.hooksPath)"
