# Використання

Вимоги: Git, Python ≥ 3.11. Для команд агента — VS Code з GitHub Copilot Chat (режим Agent).

## 1. Клонування

```bash
git clone <URL-репозиторію> AKPS
cd AKPS
git checkout develop
```

## 2. Генерація через Copilot

У Copilot Chat (режим Agent, агент `build-engineer`):

```
/init
```

Окремі кроки: `/git-init`, `/create-project`, `/create-build`, `/create-actions`, `/check`.
Усі команди ідемпотентні: повторний запуск лише виводить `SKIP`.

## 3. Локальна збірка

Linux / macOS:

```bash
./ci.sh
```

Windows (cmd):

```bat
ci.bat
```

Windows (PowerShell):

```powershell
cmd /c .\ci.bat
```

Результат: `8 passed`, `BUILD: PASSED`, файл `dist/lab1-0.1.0-py3-none-any.whl`.

## 4. Перевірка репозиторію (`/check`)

```bash
python scripts/check.py
```

Останній рядок: `STATUS: PASSED` (код 0) або `STATUS: FAILED (N check(s))` (код 1).

## 5. Запуск програми

```bash
.venv/bin/python -m lab1 add 2 3        # Linux/macOS -> 5.0
.venv\Scripts\python -m lab1 div 9 3    # Windows     -> 3.0
.venv\Scripts\python -m lab1 wc "a b c" # Windows     -> 3
```

## 6. CI

Workflow `.github/workflows/ci.yml` запускається на `push` і `pull_request` до `develop`
і `master`, матриця: `ubuntu-latest`, `windows-latest`, `macos-latest`.
Результати: вкладка **Actions** репозиторію.

## 7. Демонстрація: зламана перевірка ловиться

```bash
# зламати: прибрати .pytest_cache/ з .gitignore
sed -i '/^\.pytest_cache\/$/d' .gitignore
python scripts/check.py     # -> [FAIL] .gitignore: missing: .pytest_cache/ ; STATUS: FAILED (1 check(s))
git checkout -- .gitignore  # відновити
python scripts/check.py     # -> STATUS: PASSED
```
