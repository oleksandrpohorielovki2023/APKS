---
mode: agent
description: Оркестратор — послідовно виконує git-init, create-project, create-build, create-actions, check.
---

Дій як агент [build-engineer](../agents/build-engineer.agent.md).

Виконай команди строго в цьому порядку:

1. [/git-init](git-init.prompt.md)
2. [/create-project](create-project.prompt.md)
3. [/create-build](create-build.prompt.md)
4. [/create-actions](create-actions.prompt.md)
5. [/check](check.prompt.md)

Правила:

- Після кожного кроку зафіксуй його рядок статусу.
- Якщо крок завершився чимось, крім `STATUS: PASSED`, — **негайно зупинись**, не виконуй
  наступні кроки, виведи `INIT: FAILED at <крок>: <причина>`.
- Успіх оркестратора — **лише** якщо `/check` повернув `STATUS: PASSED`.
  Тоді виведи `INIT: PASSED`.
- Оскільки всі кроки ідемпотентні, повторний `/init` на готовому репозиторії лише
  виводить `SKIP` і завершується `INIT: PASSED` без змін у `git status`.
