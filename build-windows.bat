@echo off

echo [INFO] Проверка установки Python...
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python не установлен. Для сборки требуется версия Python 3.11
    pause
    exit /b 1
)

echo [INFO] Проверка версии Python...
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set PYTHON_MINOR=%%b
)
if %PYTHON_MINOR% NEQ 11 (
    echo [ERROR] Установлена не подходящая версия Python. Установите версию Python 3.11
    pause
    exit /b 1
)


cls
echo [INFO] Проверка виртуального окружения...
if not exist "build-venv\" (
    echo [INFO] Создание виртуального окружения...
    call python -m venv venv
)

echo [INFO] Активация виртуального окружения...
call .\build-venv\Scripts\activate.bat

set "DIST_DIR=dist\EasyVoice2Speech"
set "BUILD_DIR=build"
set "SPEC_FILE=EasyVoice2Speech.spec"

cls
echo [INFO] Установка зависимостей...
call pip install -r build-requirements.txt


cls
setlocal
FOR /F "tokens=*" %%i in ('type build_meta.env') do SET %%i
if exist build\ (
    echo [INFO] Очистка файлов сборки...
    rmdir /s /q "build"
)
if exist dist\ (
    echo [INFO] Удаление старой версии...
    rmdir /s /q "dist"
)

echo [INFO] Начало сборки...
call pyinstaller ^
    --noconfirm ^
    --onedir ^
    --windowed ^
    --name "EasySpeech2Text" ^
    --distpath "dist" ^
    --collect-all whisper ^
    --collect-all df ^
    --collect-all transformers ^
    --collect-all tokenizers ^
    --collect-all safetensors ^
    --collect-all PySide6 ^
    --collect-all openai-whisper ^
    --collect-all ffmpeg-python ^
    --collect-all torch ^
    --collect-all torchaudio ^
    --collect-all numpy ^
    --collect-all deepfilternet ^
    --collect-all soundfile ^
    --collect-all transformers ^
    --collect-all accelerate ^
    --collect-all sentencepiece ^
    --collect-all docx ^
    --collect-all hf_xet ^
    --hidden-import=multiprocessing ^
    --hidden-import=multiprocessing.spawn ^
    --hidden-import=multiprocessing.forkserver ^
    --add-data "icon.png:." ^
    --add-data "ui:ui" ^
    --add-data "ffmpeg:ffmpeg" ^
    --add-data "models:models" ^
    --icon="icon.png" ^
    main.py

if errorlevel 1 (
    echo [ERROR] Сборка завершилась с ошибкой
    pause
    pause & exit /b 1
)
endlocal

start explorer "%DIST_DIR%"