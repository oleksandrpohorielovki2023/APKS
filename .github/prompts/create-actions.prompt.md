---
mode: agent
description: Ідемпотентно створює workflow GitHub Actions на трьох ОС.
---

Дій як агент [build-engineer](../agents/build-engineer.agent.md) і використай skill
[github-actions](../skills/github-actions/SKILL.md).

1. Передумова: існують `ci.sh` і `ci.bat`. Якщо ні — `STATUS: FAILED: run /create-build first`.
2. Якщо `.github/workflows/ci.yml` відсутній — створи його згідно з розділом «Вихід» skill-а.
   Якщо існує — **не перезаписуй**, лише перевір його; при розбіжностях виведи їх і `STATUS: FAILED`.
3. Виконай перевірки skill-а (тригери, гілки, матриця ОС, відсутність `continue-on-error`).

Виведи `CREATE`/`SKIP` і `STATUS: PASSED` або `STATUS: FAILED: <причина>`.
