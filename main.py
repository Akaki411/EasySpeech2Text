import os
import sys
import urllib.request
import zipfile
import shutil
from pathlib import Path

from PySide6.QtGui import QGuiApplication, QIcon

if hasattr(sys, '_MEIPASS'):
    ROOT_DIR = Path(sys.executable).parent
else:
    ROOT_DIR = Path(__file__).parent

MODELS_DIR = ROOT_DIR / "models"
FFMPEG_DIR = ROOT_DIR / "ffmpeg"

os.environ["WHISPER_CACHE"]  = str(MODELS_DIR / "whisper")
os.environ["HF_HOME"]        = str(MODELS_DIR / "huggingface")
os.environ["HUGGINGFACE_HUB_CACHE"] = str(MODELS_DIR / "huggingface" / "hub")
os.environ["TORCH_HOME"]     = str(MODELS_DIR / "torch")
os.environ["XDG_CACHE_HOME"] = str(MODELS_DIR)

for sub in ("whisper", "huggingface/hub", "torch"):
    (MODELS_DIR / sub).mkdir(parents=True, exist_ok=True)

def download_ffmpeg(preloader=None):
    ffmpeg_url = (
        "https://www.gyan.dev/ffmpeg/builds/"
        "ffmpeg-release-essentials.zip"
    )

    ffmpeg_exe = FFMPEG_DIR / "ffmpeg.exe"
    if ffmpeg_exe.exists():
        return

    if preloader:
        preloader.set_status("Начало скачивания...")

    FFMPEG_DIR.mkdir(parents=True, exist_ok=True)
    archive_path = (FFMPEG_DIR / "ffmpeg-release.zip")
    response = urllib.request.urlopen(ffmpeg_url)
    total_size = int(response.headers.get( "Content-Length", 0))
    downloaded = 0

    with open(archive_path, "wb") as file:
        while True:
            chunk = response.read(1024 * 256)
            if not chunk:
                break
            file.write(chunk)
            downloaded += len(chunk)
            if preloader:
                preloader.update_progress(downloaded / 1024 / 1024, total_size / 1024 / 1024)

    if preloader:
        preloader.set_status("Распаковка...")

    with zipfile.ZipFile(archive_path,"r") as zip_ref:
        zip_ref.extractall(FFMPEG_DIR)

    if preloader:
        preloader.set_status("Подготовка файлов...")

    ffmpeg_found = False

    for item in os.listdir(FFMPEG_DIR):
        if ffmpeg_found:
            break
        item_path = (FFMPEG_DIR / item)
        if item_path.is_dir() and "ffmpeg" in item.lower():
            bin_path = (item_path/ "bin")
            if bin_path.exists():
                for file_name in os.listdir(bin_path):
                    if file_name== "ffmpeg.exe":
                        shutil.copy2(bin_path / file_name,ffmpeg_exe)
                        ffmpeg_found = True
                        break

    for item in os.listdir(FFMPEG_DIR):
        item_path = (FFMPEG_DIR / item)
        if item == "ffmpeg.exe":
            continue

        if item_path.is_dir():
            shutil.rmtree(item_path)
        else:
            item_path.unlink()

from ui.app import create_app
from ui.preloader import Preloader

def main():
    os.environ.setdefault("QT_QUICK_BACKEND", "software")
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Material")
    os.environ.setdefault("QT_QUICK_CONTROLS_MATERIAL_THEME", "Dark")
    os.environ.setdefault("QT_QUICK_CONTROLS_MATERIAL_ACCENT", "#29B6F6")

    app = QGuiApplication(sys.argv)
    app.setApplicationName("EasySpeech2Text")
    app.setWindowIcon(QIcon("ui/resources/icons/icon.png"))

    if not (FFMPEG_DIR / "ffmpeg.exe").exists():
        preloader = Preloader(app)
        preloader.show()
        download_ffmpeg(preloader)
        preloader.close()

    sys.exit(create_app(app))

if __name__ == "__main__":
    main()