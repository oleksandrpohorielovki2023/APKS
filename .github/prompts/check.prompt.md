---
mode: agent
description: Перевіряє репозиторій скриптом scripts/check.py і повертає STATUS PASSED або FAILED.
---

Дій як агент [build-engineer](../agents/build-engineer.agent.md).

Команда лише читає стан і нічого не змінює (ідемпотентна за визначенням).

1. Якщо `scripts/check.py` відсутній — `STATUS: FAILED: scripts/check.py missing`.
2. Виконай `python scripts/check.py` (на Windows можна `py -3 scripts/check.py`).
3. Покажи таблицю перевірок з виводу скрипта (`[OK]` / `[FAIL]`).
4. Останнім рядком відповіді повтори рядок статусу зі скрипта дослівно:
   `STATUS: PASSED` (код 0) або `STATUS: FAILED` (код ≠ 0).

**Не виправляй** нічого в межах цієї команди — лише звітуй.
