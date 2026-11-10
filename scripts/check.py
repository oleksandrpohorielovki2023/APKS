"""Repository checks for the /check command and CI.

Prints one line per check and a final ``STATUS: PASSED`` or ``STATUS: FAILED``.
Exit code is 0 only when every check passes. Read-only: changes nothing.
"""

from __future__ import annotations

import compileall
import os
import subprocess
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REQUIRED_FILES = [
    "README.md",
    "docs/architecture.md",
    "docs/usage.md",
    ".github/agents/build-engineer.agent.md",
    ".github/skills/project-scaffold/SKILL.md",
    ".github/skills/build-and-test/SKILL.md",
    ".github/skills/github-actions/SKILL.md",
    ".github/prompts/git-init.prompt.md",
    ".github/prompts/create-project.prompt.md",
    ".github/prompts/create-build.prompt.md",
    ".github/prompts/create-actions.prompt.md",
    ".github/prompts/check.prompt.md",
    ".github/prompts/init.prompt.md",
    ".github/workflows/ci.yml",
    "pyproject.toml",
    "src/lab1/__init__.py",
    "ci.sh",
    "ci.bat",
    ".gitignore",
]

GITIGNORE_ENTRIES = [".venv/", "dist/", "build/", "__pycache__/", "*.pyc", ".pytest_cache/"]
CI_OSES = ["ubuntu-latest", "windows-latest", "macos-latest"]


def read(rel: str) -> str:
    path = ROOT / rel
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def check_required_files() -> tuple[bool, str]:
    missing = [f for f in REQUIRED_FILES if not (ROOT / f).is_file()]
    return not missing, f"missing: {', '.join(missing)}" if missing else "all present"


def check_gitignore() -> tuple[bool, str]:
    lines = {line.strip() for line in read(".gitignore").splitlines()}
    missing = [e for e in GITIGNORE_ENTRIES if e not in lines]
    return not missing, f"missing: {', '.join(missing)}" if missing else "all entries present"


def check_pyproject() -> tuple[bool, str]:
    try:
        data = tomllib.loads(read("pyproject.toml"))
    except tomllib.TOMLDecodeError as exc:
        return False, f"invalid TOML: {exc}"
    project = data.get("project", {})
    if project.get("name") != "lab1":
        return False, "project.name != 'lab1'"
    dev = " ".join(project.get("optional-dependencies", {}).get("dev", []))
    if "pytest" not in dev:
        return False, "pytest not in [dev] extras"
    return True, "valid"


def check_compile() -> tuple[bool, str]:
    ok = all(
        compileall.compile_dir(ROOT / d, quiet=1, force=True, legacy=False)
        for d in ("src", "tests")
        if (ROOT / d).is_dir()
    )
    has_tests = any((ROOT / "tests").glob("test_*.py"))
    if not has_tests:
        return False, "no tests/test_*.py"
    return ok, "compiles" if ok else "syntax errors"


def check_build_scripts() -> tuple[bool, str]:
    sh, bat = read("ci.sh"), read("ci.bat")
    problems = []
    if not sh.startswith("#!/usr/bin/env bash"):
        problems.append("ci.sh: no bash shebang")
    if "set -euo pipefail" not in sh:
        problems.append("ci.sh: no 'set -euo pipefail'")
    if "errorlevel" not in bat.lower():
        problems.append("ci.bat: no errorlevel checks")
    for name, text in (("ci.sh", sh), ("ci.bat", bat)):
        if "pytest" not in text or "build" not in text:
            problems.append(f"{name}: pytest/build step missing")
    return not problems, "; ".join(problems) or "ok"


def check_workflow() -> tuple[bool, str]:
    wf = read(".github/workflows/ci.yml")
    problems = []
    for key in ("push:", "pull_request:"):
        if key not in wf:
            problems.append(f"no '{key}' trigger")
    for branch in ("develop", "master"):
        if wf.count(branch) < 2:
            problems.append(f"'{branch}' not in both triggers")
    problems += [f"os '{os_}' missing" for os_ in CI_OSES if os_ not in wf]
    if "continue-on-error: true" in wf or "|| true" in wf:
        problems.append("checks are suppressed")
    return not problems, "; ".join(problems) or "push+PR to develop/master on 3 OS"


def check_tests() -> tuple[bool, str]:
    venv_python = ROOT / ".venv" / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    if not venv_python.is_file():
        return True, "skipped (.venv not created yet, run ci script)"
    result = subprocess.run(
        [str(venv_python), "-m", "pytest", "-q"], cwd=ROOT, capture_output=True, text=True
    )
    tail = (result.stdout.strip().splitlines() or ["no output"])[-1]
    return result.returncode == 0, tail


CHECKS = [
    ("required files", check_required_files),
    (".gitignore", check_gitignore),
    ("pyproject.toml", check_pyproject),
    ("sources compile", check_compile),
    ("build scripts", check_build_scripts),
    ("CI workflow", check_workflow),
    ("pytest", check_tests),
]


def main() -> int:
    failed = 0
    for name, func in CHECKS:
        ok, detail = func()
        failed += not ok
        print(f"[{'OK' if ok else 'FAIL'}] {name}: {detail}")
    print("STATUS: PASSED" if not failed else f"STATUS: FAILED ({failed} check(s))")
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
