import os
import sys
import torchaudio

if not hasattr(torchaudio, 'backend'):
    import types

    torchaudio.backend = types.ModuleType('torchaudio.backend')
    torchaudio.backend.common = types.ModuleType('torchaudio.backend.common')
    torchaudio.backend.common.AudioMetaData = torchaudio.AudioMetaData

from df.enhance import enhance, init_df, load_audio, save_audio


def _get_df_model_dir() -> tuple[str, bool]:
    if hasattr(sys, '_MEIPASS'):
        exe_dir = os.path.dirname(sys.executable)
        model_dir = os.path.join(exe_dir, "models", "DeepFilterNet", "DeepFilterNet3")
    else:
        base = os.environ.get("XDG_CACHE_HOME", os.path.join(os.path.expanduser("~"), ".cache"))
        model_dir = os.path.join(base, "DeepFilterNet", "DeepFilterNet3")

    is_downloaded = os.path.isfile(os.path.join(model_dir, "config.ini"))
    return model_dir, is_downloaded


class Denoiser:
    def __init__(self):
        self._model = None
        self._df_state = None

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self):
        model_dir, is_downloaded = _get_df_model_dir()

        if is_downloaded:
            parent_dir = os.path.dirname(model_dir)
            self._model, self._df_state, _ = init_df(
                model_base_dir=parent_dir,
                log_level="NONE",
            )
        else:
            if hasattr(sys, '_MEIPASS'):
                exe_dir = os.path.dirname(sys.executable)
                cache_dir = os.path.join(exe_dir, "models")
                os.environ["XDG_CACHE_HOME"] = cache_dir

            self._model, self._df_state, _ = init_df(log_level="NONE")

    def unload(self):
        import torch
        self._model = None
        self._df_state = None
        torch.cuda.empty_cache()

    def denoise(self, input_path: str, output_path: str):
        if not self.is_loaded:
            raise RuntimeError("Denoiser не загружен. Вызовите load() перед использованием.")

        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        audio, _ = load_audio(input_path, sr=self._df_state.sr())

        enhanced = enhance(self._model, self._df_state, audio)
        save_audio(output_path, enhanced, self._df_state.sr())