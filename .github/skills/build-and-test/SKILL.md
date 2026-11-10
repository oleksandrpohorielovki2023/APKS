---
name: build-and-test
description: Створює та виконує локальну збірку ci.sh / ci.bat — .venv, встановлення залежностей, pytest, wheel у dist/.
---

# Skill: build-and-test

## Вхід

- Структура від `project-scaffold` (`pyproject.toml`, `src/`, `tests/`).
- Інтерпретатор: `python3` (Linux/macOS) або `python` / `py -3` (Windows).

## Вихід

- `ci.sh` (LF, виконуваний) і `ci.bat` (CRLF), що виконують однакові кроки:
  1. створити `.venv`, якщо його немає;
  2. `python -m pip install --upgrade pip`;
  3. `python -m pip install -e ".[dev]"`;
  4. `python -m pytest -q`;
  5. `python -m build --wheel --outdir dist`.
- Каталог `dist/` з `lab1-*.whl`.
- Код виходу `0` при успіху, ненульовий — на першому кроці, що впав.

## Перевірки

- `ci.sh` починається з `#!/usr/bin/env bash` і містить `set -euo pipefail`.
- `ci.bat` перевіряє `if errorlevel 1` після кожного кроку і виходить з `exit /b 1`.
- Після запуску є `dist/*.whl`; pytest звітує `passed` і `0 failed`.
- Повторний запуск не перестворює `.venv` і завершується так само успішно.

## Сценарій помилки

| Ситуація | Дія |
|----------|-----|
| Python не знайдено | `ERROR build-and-test: python not found`, код 1. |
| Не вдалося встановити залежності (мережа) | Вивести лог pip, код 1; не продовжувати до pytest. |
| Падіння тестів | Вивести звіт pytest, код 1; **не** змінювати і не видаляти тести. |
| Збірка wheel не вдалася | Вивести лог `build`, код 1. |
