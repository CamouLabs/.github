import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

_whisper_model = None


def _get_whisper():
    global _whisper_model
    if _whisper_model is None:
        from faster_whisper import WhisperModel
        from config import settings

        _whisper_model = WhisperModel(settings.whisper_model, device="cpu", compute_type="int8")
    return _whisper_model


def extract_audio_from_video(video_path: Path, output_path: Path) -> bool:
    import subprocess

    try:
        subprocess.run(
            [
                "ffmpeg", "-y", "-i", str(video_path),
                "-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1",
                str(output_path),
            ],
            check=True,
            capture_output=True,
        )
        return True
    except subprocess.CalledProcessError as e:
        logger.error("ffmpeg failed: %s", e.stderr)
        return False


def transcribe_file(file_path: Path) -> Optional[str]:
    path = Path(file_path)
    if not path.exists():
        return None

    audio_path = path
    temp_audio = None

    if path.suffix.lower() in {".mp4", ".mov", ".avi", ".mkv", ".webm"}:
        temp_audio = path.parent / f"{path.stem}_audio.wav"
        if not extract_audio_from_video(path, temp_audio):
            return None
        audio_path = temp_audio

    try:
        model = _get_whisper()
        segments, _ = model.transcribe(str(audio_path), beam_size=5)
        text = " ".join(seg.text.strip() for seg in segments)
        return text.strip() if text else None
    except Exception as e:
        logger.error("Transcription failed: %s", e)
        return None
    finally:
        if temp_audio and temp_audio.exists():
            temp_audio.unlink()

