import os
import urllib.request
import zipfile
import shutil
from pathlib import Path
from ui.app import create_app


MODELS_DIR = Path(__file__).parent / "models"
FFMPEG_DIR = Path(__file__).parent / "ffmpeg"

os.environ["WHISPER_CACHE"]  = str(MODELS_DIR / "whisper")
os.environ["HF_HOME"]        = str(MODELS_DIR / "huggingface")
os.environ["TORCH_HOME"]     = str(MODELS_DIR / "torch")
os.environ["XDG_CACHE_HOME"] = str(MODELS_DIR)

for sub in ("whisper", "huggingface", "torch", "DeepFilterNet"):
    (MODELS_DIR / sub).mkdir(parents=True, exist_ok=True)


def download_ffmpeg():
    ffmpeg_windows = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    if os.path.exists(FFMPEG_DIR / r"ffmpeg.exe"):
        return

    if not os.path.exists(FFMPEG_DIR):
        os.makedirs(FFMPEG_DIR, exist_ok=True)

    urllib.request.urlretrieve(ffmpeg_windows, FFMPEG_DIR / "ffmpeg-release.zip")

    with zipfile.ZipFile(FFMPEG_DIR / "ffmpeg-release.zip", 'r') as zip_ref:
        zip_ref.extractall(FFMPEG_DIR)

    is_copied = False
    for item in os.listdir(FFMPEG_DIR):
        if is_copied:
            break
        item_path = FFMPEG_DIR / item
        if os.path.isdir(item_path) and 'ffmpeg' in item.lower():
            bin_path = os.path.join(item_path, 'bin')
            if os.path.exists(bin_path):
                for file in os.listdir(bin_path):
                    if file == 'ffmpeg.exe':
                        if is_copied:
                            break
                        src = os.path.join(bin_path, file)
                        dst = FFMPEG_DIR / "ffmpeg.exe"
                        shutil.copy2(src, dst)
                        is_copied = True
    for item in os.listdir(FFMPEG_DIR):
        file = FFMPEG_DIR / item
        if item == 'ffmpeg.exe':
            continue
        if os.path.isdir(file):
            shutil.rmtree(file)
        else:
            os.remove(file)

if __name__ == "__main__":
    import sys
    download_ffmpeg()
    sys.exit(create_app())