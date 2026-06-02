import os
import whisper
import numpy as np
from core.converter import _get_ffmpeg_path


class Transcriber:
    def __init__(self, model_name: str = "medium", locale: str = "auto"):
        self._model = None
        self._model_name = model_name
        self._locale = locale

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self):
        self._model = whisper.load_model(self._model_name)

    def unload(self):
        import torch
        self._model = None
        self._model_name = None
        torch.cuda.empty_cache()

    def transcribe(self, audio_path: str) -> str:
        if not self.is_loaded:
            raise RuntimeError("Transcriber не загружен. Вызовите load() перед использованием.")

        ffmpeg_bin = _get_ffmpeg_path()
        ffmpeg_dir = os.path.dirname(ffmpeg_bin)
        env_path = os.environ.get("PATH", "")
        if ffmpeg_dir not in env_path:
            os.environ["PATH"] = ffmpeg_dir + os.pathsep + env_path

        audio_array = whisper.load_audio(audio_path)

        result = self._model.transcribe(
            audio_array,
            language=self._locale,
            task="transcribe",
            fp16=False,
            verbose=False,
        )
        return result["text"].strip()