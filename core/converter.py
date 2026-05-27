import ffmpeg
import tempfile
import os
import shutil
from pathlib import Path


VIDEO_EXTENSIONS = {".mp4", ".mkv", ".avi", ".mov", ".webm", ".flv", ".wmv", ".m4v"}
AUDIO_EXTENSIONS = {".mp3", ".wav", ".flac", ".ogg", ".m4a", ".aac", ".opus", ".wma"}


def _get_ffmpeg_path() -> str:
    return str(Path(__file__).parent.parent / "ffmpeg" / "ffmpeg.exe")


def is_video(file_path: str) -> bool:
    return Path(file_path).suffix.lower() in VIDEO_EXTENSIONS


def is_audio(file_path: str) -> bool:
    return Path(file_path).suffix.lower() in AUDIO_EXTENSIONS


def extract_audio(file_path: str) -> str:
    ffmpeg_bin = _get_ffmpeg_path()

    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    tmp.close()
    out_path = tmp.name

    try:
        (
            ffmpeg
            .input(file_path)
            .output(
                out_path,
                format="wav",
                acodec="pcm_s16le",
                ar=16000,
                ac=1,
            )
            .overwrite_output()
            .run(cmd=ffmpeg_bin, quiet=True)
        )
    except ffmpeg.Error as e:
        os.unlink(out_path)
        stderr = e.stderr.decode(errors="replace") if e.stderr else str(e)
        raise RuntimeError(f"Ошибка ffmpeg: {stderr}") from e

    return out_path


def prepare_audio(file_path: str) -> tuple[str, bool]:
    if is_video(file_path) or is_audio(file_path):
        return extract_audio(file_path), True
    raise ValueError(f"Неподдерживаемый формат: {Path(file_path).suffix}")