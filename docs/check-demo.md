# Етап 6: демонстрація /check

Реальний вивід `python scripts/check.py` (Windows, Python 3.13, 2026-11-10).

## 1. Еталон

```
[OK] required files: all present
[OK] .gitignore: all entries present
[OK] pyproject.toml: valid
[OK] sources compile: compiles
[OK] build scripts: ok
[OK] CI workflow: push+PR to develop/master on 3 OS
[OK] pytest: 8 passed in 0.03s
STATUS: PASSED
```

## 2. Зламано `.gitignore` (видалено `.pytest_cache/`)

```
[FAIL] .gitignore: missing: .pytest_cache/
STATUS: FAILED (1 check(s))        # exit code 1
```

## 3. Зламано логіку (`add` повертає `a - b`)

```
[FAIL] pytest: 2 failed, 6 passed in 0.11s
STATUS: FAILED (1 check(s))        # exit code 1
```

## 4. Після відновлення

```
STATUS: PASSED                     # exit code 0
```

Отже, `/check` (і `/init`, що вважає успіхом лише `STATUS: PASSED`) ловить як
порушення конфігурації, так і регресію в коді.
