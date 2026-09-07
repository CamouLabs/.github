import json
from typing import Optional

from fastapi import APIRouter, HTTPException

from database import create_entry, delete_entry, get_entry, list_entries, update_entry
from models.schemas import EntryCreate, EntryResponse, EntryUpdate, ProcessResult
from services.pipeline import process_entry

router = APIRouter(prefix="/api/entries", tags=["entries"])


def _parse_entry(row: dict) -> dict:
    tags = row.get("tags", "[]")
    if isinstance(tags, str):
        tags = json.loads(tags)
    return {**row, "tags": tags}


@router.post("", response_model=EntryResponse)
async def create_entry_endpoint(body: EntryCreate):
    entry = await create_entry(
        title=body.title,
        content=body.content,
        media_type=body.media_type,
        mood=body.mood,
        tags=body.tags,
    )
    return _parse_entry(entry)


@router.get("")
async def list_entries_endpoint(limit: int = 100, offset: int = 0):
    entries = await list_entries(limit, offset)
    return [_parse_entry(e) for e in entries]


@router.get("/{entry_id}", response_model=EntryResponse)
async def get_entry_endpoint(entry_id: str):
    entry = await get_entry(entry_id)
    if not entry:
        raise HTTPException(404, "Entry not found")
    return _parse_entry(entry)


@router.put("/{entry_id}", response_model=EntryResponse)
async def update_entry_endpoint(entry_id: str, body: EntryUpdate):
    entry = await update_entry(entry_id, **body.model_dump(exclude_unset=True))
    if not entry:
        raise HTTPException(404, "Entry not found")
    return _parse_entry(entry)


@router.delete("/{entry_id}")
async def delete_entry_endpoint(entry_id: str):
    await delete_entry(entry_id)
    return {"ok": True}


@router.post("/{entry_id}/process", response_model=ProcessResult)
async def process_entry_endpoint(entry_id: str):
    result = await process_entry(entry_id)
    if "error" in result:
        raise HTTPException(400, result["error"])
    return result
