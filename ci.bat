@echo off
rem Local build: venv -> install -> tests -> wheel. Same steps as ci.sh.
setlocal
cd /d "%~dp0"

if "%PYTHON%"=="" set "PYTHON=python"
%PYTHON% --version >nul 2>&1
if errorlevel 1 (
  echo ERROR build-and-test: python not found
  exit /b 1
)

if not exist .venv (
  echo == create .venv
  %PYTHON% -m venv .venv
  if errorlevel 1 exit /b 1
)
set "VPY=.venv\Scripts\python.exe"

echo == install
"%VPY%" -m pip install --upgrade pip -q
if errorlevel 1 exit /b 1
"%VPY%" -m pip install -e ".[dev]" -q
if errorlevel 1 exit /b 1

echo == pytest
"%VPY%" -m pytest -q
if errorlevel 1 exit /b 1

echo == build
"%VPY%" -m build --wheel --outdir dist
if errorlevel 1 exit /b 1

echo BUILD: PASSED
exit /b 0
