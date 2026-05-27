import os
import torchaudio

if not hasattr(torchaudio, 'backend'):
    import types
    torchaudio.backend = types.ModuleType('torchaudio.backend')
    torchaudio.backend.common = types.ModuleType('torchaudio.backend.common')
    torchaudio.backend.common.AudioMetaData = torchaudio.AudioMetaData

from df.enhance import enhance, init_df, load_audio, save_audio


class Denoiser:
    def __init__(self):
        self._model = None
        self._df_state = None

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self):
        self._model, self._df_state, _ = init_df()

    def unload(self):
        import torch
        self._model = None
        self._df_state = None
        torch.cuda.empty_cache()

    def denoise(self, input_path: str, output_path: str, progress_callback=None):
        if not self.is_loaded:
            raise RuntimeError("Denoiser не загружен. Вызовите load() перед использованием.")

        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        audio, _ = load_audio(input_path, sr=self._df_state.sr())
        enhanced = enhance(self._model, self._df_state, audio)
        save_audio(output_path, enhanced, self._df_state.sr())