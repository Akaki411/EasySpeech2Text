@echo off

echo Проверка установки Python...
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python не установлен. Установите версию не ниже 3.11
    exit /b 1
)

echo Проверка версии Python...
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set PYTHON_MINOR=%%b
)
if %PYTHON_MINOR% LSS 11 (
	echo Установлена старая версия Python. Установите версию не ниже 3.11
    exit /b 1
)

echo Проверка виртуального окружения...
if not exist "venv\" (
	echo Создание виртуального окружения...
    call python -m venv venv
)

echo Активация виртуального окружения...
call .\venv\Scripts\activate.bat

cls
echo Установка зависимостей...
call pip install -r requirements.txt

cls
call python main.py

if errorlevel 1 (
    echo [ERROR] Программа завершилась с ошибкой
    pause
    pause & exit /b 1
)