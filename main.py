import os
from pathlib import Path

MODELS_DIR = Path(__file__).parent / "models"

os.environ["WHISPER_CACHE"]  = str(MODELS_DIR / "whisper")
os.environ["HF_HOME"]        = str(MODELS_DIR / "huggingface")
os.environ["TORCH_HOME"]     = str(MODELS_DIR / "torch")
os.environ["XDG_CACHE_HOME"] = str(MODELS_DIR)

for sub in ("whisper", "huggingface", "torch", "DeepFilterNet"):
    (MODELS_DIR / sub).mkdir(parents=True, exist_ok=True)

from ui.app import create_app

if __name__ == "__main__":
    import sys
    sys.exit(create_app())