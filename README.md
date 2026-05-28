# EasySpeech2Text

Десктопное приложение для транскрибации аудио и видео файлов в текст с шумоподавлением и нормализацией через локальную LLM. Работает полностью офлайн после первого запуска.

![Python](https://img.shields.io/badge/Python-3.11.9-blue)
![PySide6](https://img.shields.io/badge/PySide6-6.7.2-green)
![Whisper](https://img.shields.io/badge/Whisper-medium-orange)
![License](https://img.shields.io/badge/License-GPL-lightgrey)

---

## Возможности

- **Транскрибация** аудио и видео файлов через OpenAI Whisper
- **Шумоподавление** через DeepFilterNet перед транскрибацией
- **Нормализация текста** через локальную LLM
- **Сохранение результатов** в `.docx` формат
- Поддержка форматов: `MP4 MKV AVI MOV WEBM MP3 WAV FLAC OGG M4A AAC OPUS WMA`
- Выбор модели Whisper: `tiny / base / small / medium / large`

---
## Внимание
**Во время первого запуска программы** загружаются необходимые модели, из-за чего первый запуск **может занять некоторое время**

---

## Структура проекта

``` python
EasySpeech2Text/
├── main.py                  # Точка входа
├── requirements.txt         # Рабочие зависимости проекта
├── run-windows.bat          # Рабочие зависимости проекта
├── build-requirements.txt   # Зависимости для сборки через PyInstaller
├── build-windows.bat        # Сборка через PyInstaller
├── inno.setup.config.iss    # Конфигурация сборки установщика Inno Setup
│
├── core/
│   ├── __init__.py
│   ├── converter.py         # Конвертация медиафайлов в WAV (ffmpeg)
│   ├── denoiser.py          # Шумоподавление (DeepFilterNet)
│   ├── transcriber.py       # Транскрибация (Whisper)
│   └── llm.py               # Нормализация текста (Qwen2.5-3B)
│
├── ui/
│   ├── __init__.py
│   ├── app.py               # Backend и пайплайн
│   ├── main.qml             # Интерфейс
│   └── resources/
│       ├── icons/           # Иконки приложения
│       └── vector/          # SVG рисунки для интерфейса
│
├── utils/
│   ├── __init__.py
│   └── file_utils.py        # Утилиты файловой системы
│
└── models/                  # Кэш моделей (создаётся автоматически)
    ├── whisper/
    ├── huggingface/
    ├── torch/
    └── DeepFilterNet/
```

---

## Требования

### Системные зависимости

- **Python 3.11.9**

### Список зависимостей

``` python
PySide6==6.11.1
openai-whisper==20250625
ffmpeg-python==0.2.0
torch==2.1.2
torchaudio==2.1.2
numpy==1.26.4
deepfilternet==0.5.6
soundfile==0.13.1
transformers==4.44.2
accelerate==0.33.0
sentencepiece==0.2.0
python-docx==1.1.2
hf_xet==1.5.0
```

---

## Установка и запуск

```bat
:: 1. Клонировать репозиторий
git clone https://github.com/Akaki411/EasySpeech2Text.git
cd EasySpeech2Text

:: 2. Создать виртуальное окружение
python -m venv venv
venv\Scripts\activate

:: 3. Установить зависимости
pip install -r requirements.txt

:: 4. Запустить
python main.py
```

При первом запуске модели скачаются автоматически:

| Модель | Размер |
|--------|--------|
| Whisper medium | ~1.5 GB |
| DeepFilterNet3 | ~30 MB |
| Qwen2.5-3B-Instruct | ~6 GB |

---

## Сборка дистрибутива

```bat
:: Собрать .exe через PyInstaller
build-windows.bat
```

Результат — папка `dist\EasySpeech2Text\` со всем необходимым.

После чего есть возможность собрать установочный файл через **Inno Setup Compiller**  

---

## Модели Whisper

| Модель | Размер | VRAM | Скорость | Качество |
|--------|--------|------|----------|----------|
| tiny   | 75 MB  | 1 GB | ★★★★★ | ★☆☆☆☆ |
| base   | 142 MB | 1 GB | ★★★★☆ | ★★☆☆☆ |
| small  | 466 MB | 2 GB | ★★★☆☆ | ★★★☆☆ |
| medium | 1.5 GB | 5 GB | ★★☆☆☆ | ★★★★☆ |
| large  | 3 GB   | 10 GB| ★☆☆☆☆ | ★★★★★ |

Рекомендуется **medium** — оптимальный баланс скорости и качества для русского языка.