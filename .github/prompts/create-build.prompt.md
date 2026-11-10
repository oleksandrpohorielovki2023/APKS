---
mode: agent
description: Ідемпотентно створює ci.sh і ci.bat для локальної збірки та тестів.
---

Дій як агент [build-engineer](../agents/build-engineer.agent.md) і використай skill
[build-and-test](../skills/build-and-test/SKILL.md).

1. Передумова: існує `pyproject.toml`. Якщо ні — `STATUS: FAILED: run /create-project first`.
2. Якщо `ci.sh` відсутній — створи його (LF, shebang, `set -euo pipefail`) і виконай
   `git update-index --chmod=+x ci.sh`. Якщо існує — `SKIP`.
3. Якщо `ci.bat` відсутній — створи (CRLF, перевірка `errorlevel` після кожного кроку). Якщо існує — `SKIP`.
4. Обидва скрипти мають: створювати `.venv` лише якщо його немає; встановлювати `-e ".[dev]"`;
   запускати `pytest`; збирати wheel у `dist/`.
5. Запусти скрипт для поточної ОС і переконайся, що код виходу 0 і `dist/*.whl` існує.

Виведи `CREATE`/`SKIP` і `STATUS: PASSED` або `STATUS: FAILED: <причина>` (з хвостом логу).
