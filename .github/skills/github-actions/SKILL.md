---
name: github-actions
description: Створює workflow .github/workflows/ci.yml, що запускає ci.sh / ci.bat на ubuntu, windows, macos для push і pull_request у develop і master.
---

# Skill: github-actions

## Вхід

- Робочі `ci.sh` і `ci.bat` (від `build-and-test`).
- `scripts/check.py`.
- Гілки-цілі: `develop`, `master`.

## Вихід

`.github/workflows/ci.yml`:

- `on.push.branches` і `on.pull_request.branches` = `[develop, master]`;
- `strategy.matrix.os` = `[ubuntu-latest, windows-latest, macos-latest]`, `fail-fast: false`;
- кроки: `actions/checkout@v4` → `actions/setup-python@v5` (3.12) →
  `python scripts/check.py` → `./ci.sh` (Unix) / `ci.bat` (Windows) →
  `actions/upload-artifact@v4` з `dist/`.

## Перевірки

- YAML парситься (`python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" .github/workflows/ci.yml`
  або перевірка в `scripts/check.py`).
- Присутні тригери `push` і `pull_request` з обома гілками.
- Матриця містить усі три ОС.
- Немає `continue-on-error: true` та `|| true`.
- Після пушу: усі 3 job-и зелені на вкладці **Actions**.

## Сценарій помилки

| Ситуація | Дія |
|----------|-----|
| Workflow не запустився | Перевірити назви гілок у `on:` і що файл лежить у `.github/workflows/`. |
| Job впав лише на одній ОС | Відкрити лог job-а, відтворити локально (`ci.bat` для Windows), виправити скрипт, не ОС-матрицю. |
| Невалідний YAML | `ERROR github-actions: invalid workflow YAML`, FAILED. |
