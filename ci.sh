#!/usr/bin/env bash
# Local build: venv -> install -> tests -> wheel. Same steps as ci.bat.
set -euo pipefail
cd "$(dirname "$0")"

PY="${PYTHON:-python3}"
command -v "$PY" >/dev/null 2>&1 || { echo "ERROR build-and-test: python not found"; exit 1; }

if [ ! -d .venv ]; then
  echo "== create .venv"
  "$PY" -m venv .venv
fi
VPY=.venv/bin/python

echo "== install"
"$VPY" -m pip install --upgrade pip -q
"$VPY" -m pip install -e ".[dev]" -q

echo "== pytest"
"$VPY" -m pytest -q

echo "== build"
"$VPY" -m build --wheel --outdir dist

echo "BUILD: PASSED"
