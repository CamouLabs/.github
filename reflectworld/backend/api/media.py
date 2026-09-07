import json
import uuid
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, UploadFile

from config import ALLOWED_EXTENSIONS, UPLOADS_DIR, settings
from database import create_entry, get_entry, update_entry
from services.pipeline import process_entry
from services.transcription import transcribe_file

router = APIRouter(prefix="/api/media", tags=["media"])


@router.post("/upload")
async def upload_media(file: UploadFile = File(...)):
    ext = Path(file.filename or "").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"File type {ext} not allowed")

    content = await file.read()
    max_bytes = settings.max_upload_mb * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(400, f"File exceeds {settings.max_upload_mb}MB limit")

    safe_name = f"{uuid.uuid4()}{ext}"
    dest = UPLOADS_DIR / safe_name
    dest.write_bytes(content)

    media_type = "video" if ext in {".mp4", ".mov", ".avi", ".mkv", ".webm"} else "audio"
    return {
        "filename": safe_name,
        "path": str(dest),
        "media_type": media_type,
        "size": len(content),
    }


@router.post("/transcribe")
async def transcribe_media(file: UploadFile = File(...)):
    ext = Path(file.filename or "").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"File type {ext} not allowed")

    content = await file.read()
    safe_name = f"{uuid.uuid4()}{ext}"
    dest = UPLOADS_DIR / safe_name
    dest.write_bytes(content)

    transcript = transcribe_file(dest)
    if not transcript:
        raise HTTPException(500, "Transcription failed")

    return {"transcript": transcript, "path": str(dest)}


@router.post("/create-entry")
async def create_media_entry(
    file: UploadFile = File(...),
    title: str = "",
    mood: str = "",
):
    """Upload media, transcribe, create entry, and process through memory pipeline."""
    ext = Path(file.filename or "").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"File type {ext} not allowed")

    content = await file.read()
    safe_name = f"{uuid.uuid4()}{ext}"
    dest = UPLOADS_DIR / safe_name
    dest.write_bytes(content)

    media_type = "video" if ext in {".mp4", ".mov", ".avi", ".mkv", ".webm"} else "audio"
    transcript = transcribe_file(dest)

    entry = await create_entry(
        title=title or f"Voice note — {media_type}",
        content=transcript or "",
        media_type=media_type,
        media_path=str(dest),
        transcript=transcript,
        mood=mood or None,
    )

    if transcript:
        await process_entry(entry["id"])

    tags = entry.get("tags", "[]")
    if isinstance(tags, str):
        tags = json.loads(tags)
    return {**entry, "tags": tags, "processed": 1 if transcript else 0}
