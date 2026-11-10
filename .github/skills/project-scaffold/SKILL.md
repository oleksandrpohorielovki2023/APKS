---
name: project-scaffold
description: Створює мінімальну структуру Python-проєкту (pyproject.toml, src/lab1, tests) без перезапису наявних файлів.
---

# Skill: project-scaffold

## Вхід

- Корінь git-репозиторію (поточна директорія).
- Назва пакета: `lab1` (за замовчуванням).
- Python ≥ 3.11.

## Вихід

```
pyproject.toml          # setuptools, project.name = "lab1", extras [dev] = pytest, build
src/lab1/__init__.py    # __version__
src/lab1/core.py        # бізнес-логіка (чисті функції)
src/lab1/__main__.py    # CLI: python -m lab1
tests/test_core.py      # pytest-тести для core.py
.gitattributes          # *.sh eol=lf, *.bat eol=crlf
```

## Алгоритм (ідемпотентний)

1. Для кожного файла з переліку: якщо файл існує — **не змінювати**, записати `SKIP <файл>`.
2. Якщо не існує — створити, записати `CREATE <файл>`.
3. Не видаляти жодних файлів.

## Перевірки

- `python -c "import tomllib; tomllib.load(open('pyproject.toml','rb'))"` — валідний TOML.
- `pyproject.toml` містить `[project]`, `name = "lab1"`, `[project.optional-dependencies]` з `pytest`.
- Існують `src/lab1/__init__.py` і хоча б один `tests/test_*.py`.
- `python -m compileall -q src tests` — без синтаксичних помилок.

## Сценарій помилки

| Ситуація | Дія |
|----------|-----|
| Невалідний `pyproject.toml` | Зупинитися, вивести `ERROR project-scaffold: invalid pyproject.toml`, показати помилку парсера. Не перезаписувати файл. |
| Синтаксична помилка в `src/` чи `tests/` | `ERROR project-scaffold: compile failed`, показати файл і рядок, повернути FAILED. |
| Немає git-репозиторію | `ERROR project-scaffold: run /git-init first`, FAILED. |
