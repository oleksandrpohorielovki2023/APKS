---
mode: agent
description: Ідемпотентно ініціалізує git-репозиторій, гілки master/develop/lab1/finish і .gitignore.
---

Дій як агент [build-engineer](../agents/build-engineer.agent.md).

Виконай кроки; кожен крок спочатку перевіряє стан і нічого не робить, якщо він уже досягнутий:

1. Якщо `git rev-parse --is-inside-work-tree` не повертає `true` — `git init -b master`
   і порожній коміт `chore: initial commit`. Інакше `SKIP git init`.
2. Якщо немає гілки `master` — створити. Якщо немає `develop` — `git branch develop master`.
3. Якщо немає `lab1/finish` — `git checkout -b lab1/finish develop`; якщо є — `git checkout lab1/finish`.
4. `.gitignore`: для кожного рядка з переліку додай його **лише якщо його ще немає**:
   `.venv/`, `dist/`, `build/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`, `*.egg-info/`.
   Не змінюй і не переставляй наявні рядки.

Не роби `push`, не змінюй історію.

Наприкінці виведи список `CREATE`/`SKIP` для кожного кроку і рядок
`STATUS: PASSED` або `STATUS: FAILED: <причина>`.
