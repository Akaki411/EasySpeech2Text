import sys
import os
import gc
import winreg
from pathlib import Path
from urllib.parse import unquote, urlparse
from docx import Document
from PySide6.QtCore import QObject, Signal, Slot, QThread, QUrl
from PySide6.QtQml import QQmlApplicationEngine

from core.converter import prepare_audio
from core.denoiser import Denoiser
from core.transcriber import Transcriber
from core.llm import LLMNormalizer
from utils.file_utils import friendly_size
import api
from database import KeysDatabase


def _resolve_path(file_url: str) -> str:
    url = QUrl(file_url)
    path = url.toLocalFile()
    if not path:
        parsed = urlparse(file_url)
        path = unquote(parsed.path)
        if path.startswith("/") and len(path) > 2 and path[2] == ":":
            path = path[1:]
    return os.path.normpath(path)


def _get_output_dir(file_path: str) -> Path:
    stem = Path(file_path).stem
    base = None
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER,r"Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders")
        documents_path, _ = winreg.QueryValueEx(key, "Personal")
        winreg.CloseKey(key)
        base = Path(documents_path) / "EasySpeech2Text" / stem
    except:
        base = Path.home() / "Documents" / "EasySpeech2Text" / stem
    finally:
        base.mkdir(parents=True, exist_ok=True)
        return base


def _save_docx(text: str, output_path: Path):
    doc = Document()
    for paragraph in text.split("\n"):
        if paragraph.strip():
            doc.add_paragraph(paragraph.strip())
    doc.save(str(output_path))


class TranscriptionWorker(QThread):
    progress =            Signal(str)
    finished =            Signal(bool)
    error =               Signal(str)
    denoise_status =      Signal(str)
    whisper_status =      Signal(str)
    deepseek_status =     Signal(str)
    get_raw_text =        Signal(str)
    get_normalized_text = Signal(str)

    def __init__(self, file_path: str, whisper_model_name: str, llm_model_name: str, locale: str, denoise: bool, use_whisper: bool, use_llm: bool, cloud=None):
        super().__init__()
        self._file_path = file_path
        self._whisper_model_name = whisper_model_name
        self._llm_model_name = llm_model_name
        self._locale = locale
        self._denoise = denoise
        self._use_whisper = use_whisper
        self._use_llm = use_llm
        self._cloud = cloud

    def run(self):
        try:
            stem      = Path(self._file_path).stem
            out_dir   = _get_output_dir(self._file_path)
            raw_wav   = out_dir / f"{stem}_raw.wav"
            clean_wav = out_dir / f"{stem}_raw_denoise.wav"

            for item in out_dir.iterdir():
                if item.is_file():
                    item.unlink()
                    print(f"Удален файл: {item}")

            # Конвертация в WAV
            self.progress.emit("Конвертация...")
            tmp_wav, should_delete = prepare_audio(self._file_path)
            import shutil
            shutil.move(tmp_wav, str(raw_wav))

            # Шумоподавление
            wav_for_transcription = raw_wav
            if self._denoise:
                self.progress.emit("Загрузка DeepFilter...")
                self.denoise_status.emit("loading")
                denoiser = Denoiser()
                denoiser.load()

                self.progress.emit("Очистка от шумов...")
                self.denoise_status.emit("process")
                denoiser.denoise(str(raw_wav), str(clean_wav))

                denoiser.unload()
                del denoiser
                gc.collect()
                self.progress.emit("Выгрузка DeepFilter...")
                self.denoise_status.emit("done")
                wav_for_transcription = clean_wav


            # Транскрибация
            if self._use_whisper:
                self.progress.emit(f"Загрузка Whisper...")
                self.whisper_status.emit("loading")
                transcriber = Transcriber(self._whisper_model_name, self._locale)
                transcriber.load()

                self.progress.emit("Транскрибация...")
                self.whisper_status.emit("process")
                transcript = transcriber.transcribe(str(wav_for_transcription))

                self.get_raw_text.emit(transcript)

                transcriber.unload()
                del transcriber
                gc.collect()
                self.progress.emit("Whisper выгружен")
                self.whisper_status.emit("done")
                final_text = transcript
            else:
                self.finished.emit(True)
                self.progress.emit("Готово!")
                return

            # Нормализация
            if self._use_llm:
                if self._cloud:
                    self.progress.emit("Запрос к облачной LLM…")
                    self.deepseek_status.emit("process")
                    prompt = LLMNormalizer.NORMALIZE_PROMPT.format(text=transcript)
                    final_text = api.chat(self._cloud["provider"], self._cloud["key"], self._cloud["model"], prompt)

                    self.get_normalized_text.emit(final_text)
                    self.deepseek_status.emit("done")
                else:
                    self.progress.emit("Загрузка LLM...")
                    self.deepseek_status.emit("loading")
                    normalizer = LLMNormalizer(self._llm_model_name)
                    normalizer.load()

                    self.progress.emit("Нормализация текста…")
                    self.deepseek_status.emit("process")
                    final_text = normalizer.normalize(transcript)

                    self.get_normalized_text.emit(final_text)

                    normalizer.unload()
                    del normalizer
                    gc.collect()
                    self.progress.emit("DeepSeek выгружен")
                    self.deepseek_status.emit("done")

            self.finished.emit(True)
            self.progress.emit("Готово!")

        except Exception as e:
            import traceback
            print(f"{e}\n{traceback.format_exc()}")
            self.error.emit(f"{e}\n{traceback.format_exc()}")


class KeyCheckWorker(QThread):
    done = Signal(str, str, bool, list, str)

    def __init__(self, provider: str, key: str):
        super().__init__()
        self._provider = provider
        self._key = key

    def run(self):
        try:
            models = api.list_models(self._provider, self._key)
            self.done.emit(self._provider, self._key, True, models, "")
        except Exception as e:
            self.done.emit(self._provider, self._key, False, [], str(e))


class Backend(QObject):
    statusChanged =         Signal(str)
    getRawText =            Signal(str)
    getNormalizedText =     Signal(str)
    filterStatusChanged =   Signal(str)
    whisperStatusChanged =  Signal(str)
    deepSeekStatusChanged = Signal(str)
    busyChanged =           Signal(bool)
    readyChanged =          Signal(bool)
    keyChecked =            Signal(str, bool, str)
    cloudModelsChanged =    Signal(list)

    def __init__(self):
        super().__init__()
        self._file_path = ""
        self._busy = False
        self._model_ready = False
        self._worker = None
        self._loader = None
        self._db = KeysDatabase()
        self._cloud = {}
        self._checkers = []
        for record in self._db.get_all_keys():
            self._cloud[record["provider"]] = {"key": record["api_key"], "models": record["models"]}

    @Slot(str, str, str, bool, bool, bool)
    def transcribeFile(self, whisper_model_name: str = "medium", llm_model_name: str = "", locale: str = "auto", denoise: bool = True, use_whisper: bool = True, use_llm: bool = True):
        if self._busy:
            return
        self.getRawText.emit("")
        self.getNormalizedText.emit("")

        self._set_busy(True)

        cloud = None
        if api.is_cloud(llm_model_name):
            provider, model = api.parse_cloud(llm_model_name)
            cloud = {"provider": provider, "model": model, "key": self._db.get_key(provider)}

        self._worker = TranscriptionWorker(self._file_path, whisper_model_name, llm_model_name, locale, denoise, use_whisper, use_llm, cloud)
        self._worker.progress.connect(self.statusChanged)

        self._worker.finished.connect(self._on_done)
        self._worker.error.connect(self._on_error)
        self._worker.get_raw_text.connect(self._on_get_raw_text)
        self._worker.get_normalized_text.connect(self._on_get_normalized_text)
        self._worker.denoise_status.connect(self._on_denoise_event)
        self._worker.whisper_status.connect(self._on_whisper_event)
        self._worker.deepseek_status.connect(self._on_deepseek_event)
        self._worker.start()

    @Slot(str, result=str)
    def getFileInfo(self, file_url: str) -> str:
        try:
            self._file_path = _resolve_path(file_url)
            self.readyChanged.emit(True)
            return f"{Path(self._file_path).name}  ·  {friendly_size(self._file_path)}"
        except:
            self.readyChanged.emit(False)
            return f"Файл не найден: {self._file_path}"

    @Slot(str, str)
    def saveToDocx(self, content: str, suffix: str = ""):
        stem = Path(self._file_path).stem
        out_dir = _get_output_dir(self._file_path)
        docx = out_dir / f"{stem}{suffix}.docx"
        _save_docx(content, docx)
        os.startfile(out_dir)

    @Slot(result="QVariantList")
    def loadKeys(self) -> list:
        saved = {record["provider"]: record["api_key"] for record in self._db.get_all_keys()}
        return [
            {"name": provider, "key": saved.get(provider, ""), "isValid": provider in saved}
            for provider in api.PROVIDERS
        ]

    @Slot(result="QVariantList")
    def loadCloudModels(self) -> list:
        return self._build_cloud_models()

    @Slot(str, str)
    def checkKey(self, provider: str, key: str):
        key = key.strip()
        if not key:
            self.keyChecked.emit(provider, False, "Пустой ключ")
            return

        worker = KeyCheckWorker(provider, key)
        worker.done.connect(self._on_key_checked)
        worker.finished.connect(lambda w=worker: self._checkers.remove(w))
        self._checkers.append(worker)
        worker.start()

    def _on_key_checked(self, provider: str, key: str, ok: bool, models: list, message: str):
        if ok:
            self._db.save_key(provider, key, models)
            self._cloud[provider] = {"key": key, "models": models}
            self.cloudModelsChanged.emit(self._build_cloud_models())
        else:
            self._db.delete_key(provider)
            self._cloud.pop(provider, None)
            self.cloudModelsChanged.emit(self._build_cloud_models())
        self.keyChecked.emit(provider, ok, message)

    def _build_cloud_models(self) -> list:
        models = []
        for provider, info in self._cloud.items():
            for model in info["models"]:
                models.append({"code": api.cloud_code(provider, model), "name": f"{model} · {provider}"})
        return models

    def _on_get_raw_text(self, text: str):
        self.getRawText.emit(text)

    def _on_get_normalized_text(self, text: str):
        self.getNormalizedText.emit(text)

    def _on_done(self):
        self._set_busy(False)
        self.statusChanged.emit("Готово.")

    def _on_error(self, msg: str):
        self.statusChanged.emit(f"Ошибка: {msg}")
        self._set_busy(False)

    def _on_denoise_event(self, value: str):
        self.filterStatusChanged.emit(value)

    def _on_whisper_event(self, value: str):
        self.whisperStatusChanged.emit(value)

    def _on_deepseek_event(self, value: str):
        self.deepSeekStatusChanged.emit(value)

    def _set_busy(self, value: bool):
        self._busy = value
        self.busyChanged.emit(value)


def create_app(app) -> int:
    backend = Backend()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)

    qml_path = Path(__file__).parent / "main.qml"
    print(f"[DEBUG] QML path: {qml_path}")
    print(f"[DEBUG] QML exists: {qml_path.exists()}")

    engine.load(QUrl.fromLocalFile(str(qml_path)))

    roots = engine.rootObjects()
    print(f"[DEBUG] Root objects: {roots}")

    if not roots:
        print("[ERROR] QML не загрузился — проверьте ошибки")
        return 1

    print("[DEBUG] Запуск event loop")
    return app.exec()