---
mode: agent
description: Ідемпотентно створює Python-проєкт lab1 (pyproject.toml, src/lab1, tests).
---

Дій як агент [build-engineer](../agents/build-engineer.agent.md) і використай skill
[project-scaffold](../skills/project-scaffold/SKILL.md).

1. Передумова: робоче дерево — git-репозиторій. Якщо ні — `STATUS: FAILED: run /git-init first`.
2. Створи **лише відсутні** файли з розділу «Вихід» skill-а. Наявні файли не перезаписуй.
3. Вміст:
   - `src/lab1/core.py` — чисті функції `add`, `divide` (кидає `ValueError` при діленні на 0),
     `word_count(text)`;
   - `src/lab1/__main__.py` — CLI на `argparse`: `python -m lab1 add 2 3`, `python -m lab1 wc "a b"`;
   - `tests/test_core.py` — тести для всіх функцій, включно з помилкою ділення на 0;
   - `pyproject.toml` — `requires-python = ">=3.11"`, extras `dev = ["pytest>=8", "build>=1"]`,
     `[tool.pytest.ini_options] testpaths = ["tests"]`.
4. Виконай перевірки skill-а (TOML, compileall).

Виведи `CREATE`/`SKIP` для кожного файла і `STATUS: PASSED` або `STATUS: FAILED: <причина>`.
