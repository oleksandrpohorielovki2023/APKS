# Архітектура

## Шари

```
Користувач ──/init──▶ prompts/init.prompt.md (оркестратор)
                         │  виконує послідовно, зупиняється на першій помилці
                         ▼
   /git-init → /create-project → /create-build → /create-actions → /check
                         │
                         ▼
             agents/build-engineer.agent.md  (роль, межі, критерії завершення)
                         │ використовує
                         ▼
   skills/project-scaffold   skills/build-and-test   skills/github-actions
                         │
                         ▼
   Артефакти репозиторію: src/, tests/, pyproject.toml, ci.sh, ci.bat,
   .gitignore, .github/workflows/ci.yml, scripts/check.py
```

## Компоненти

| Компонент | Файл | Відповідальність |
|-----------|------|------------------|
| Агент | `.github/agents/build-engineer.agent.md` | Роль build-інженера, заборонені дії, Definition of Done |
| Skill | `.github/skills/project-scaffold/SKILL.md` | Структура Python-проєкту |
| Skill | `.github/skills/build-and-test/SKILL.md` | `.venv`, встановлення, pytest, збірка wheel |
| Skill | `.github/skills/github-actions/SKILL.md` | Workflow CI на 3 ОС |
| Command | `.github/prompts/git-init.prompt.md` | Репозиторій, гілки, `.gitignore` |
| Command | `.github/prompts/create-project.prompt.md` | Код + тести |
| Command | `.github/prompts/create-build.prompt.md` | `ci.sh`, `ci.bat` |
| Command | `.github/prompts/create-actions.prompt.md` | `.github/workflows/ci.yml` |
| Command | `.github/prompts/check.prompt.md` | Запуск `scripts/check.py` → `PASSED`/`FAILED` |
| Orchestrator | `.github/prompts/init.prompt.md` | Послідовний запуск усіх команд |

## Принципи

1. **Ідемпотентність.** Кожна команда спочатку перевіряє стан і створює/змінює лише те,
   чого бракує. Повторний запуск не змінює робоче дерево.
2. **Fail fast.** `/init` зупиняється на першому кроці з помилкою; успіх — лише
   `STATUS: PASSED` від `/check`.
3. **Єдине джерело правди для перевірок** — `scripts/check.py`; його ж викликає CI.
4. **Однакова збірка локально і в CI**: workflow лише викликає `ci.sh` / `ci.bat`.
