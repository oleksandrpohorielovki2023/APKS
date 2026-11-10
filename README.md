# Лабораторна робота №1 — Агентна автоматизація збірки

| Поле     | Значення                         |
|----------|----------------------------------|
| ПІБ      | Погорєлов Олександр Ігорович     |
| Група    | КІ-402                           |
| Варіант  | 2                                |

## Мета

Побудувати конфігурацію агента GitHub Copilot (`build-engineer`), набір skills і
slash-commands, які з нуля створюють Python-проєкт, локальну збірку (`ci.sh` / `ci.bat`)
і CI у GitHub Actions на трьох ОС, а також перевіряють результат командою `/check`.

## Структура

```
.github/
  agents/build-engineer.agent.md    # роль агента
  skills/<name>/SKILL.md            # project-scaffold, build-and-test, github-actions
  prompts/<name>.prompt.md          # git-init, create-project, create-build,
                                    # create-actions, check, init (оркестратор)
  workflows/ci.yml                  # CI: push / pull_request -> develop, master
src/lab1/                           # код проєкту
tests/                              # pytest
scripts/check.py                    # перевірки для /check (PASSED / FAILED)
ci.sh, ci.bat                       # локальна збірка
docs/architecture.md, docs/usage.md
```

## Швидкий старт

Див. [docs/usage.md](docs/usage.md).

## Гілки

- `master` — стабільна гілка
- `develop` — інтеграційна гілка
- `lab1/finish` — робоча гілка лабораторної, PR `lab1/finish` → `develop`
