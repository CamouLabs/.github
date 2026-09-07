import json
import uuid
from datetime import datetime, timezone
from typing import Any, Optional

import aiosqlite

from config import DATA_DIR

DB_PATH = DATA_DIR / "reflectworld.db"

SCHEMA = """
CREATE TABLE IF NOT EXISTS entries (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    media_type TEXT NOT NULL DEFAULT 'text',
    media_path TEXT,
    transcript TEXT,
    mood TEXT,
    tags TEXT DEFAULT '[]',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    processed INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS insights (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    empathy_score REAL DEFAULT 0.8,
    related_memory_ids TEXT DEFAULT '[]',
    created_at TEXT NOT NULL,
    delivered INTEGER DEFAULT 0,
    read INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY
);
INSERT OR IGNORE INTO schema_version (version) VALUES (1);
"""


async def get_db() -> aiosqlite.Connection:
    db = await aiosqlite.connect(DB_PATH)
    db.row_factory = aiosqlite.Row
    await db.executescript(SCHEMA)
    return db


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _new_id() -> str:
    return str(uuid.uuid4())


async def create_entry(
    title: str = "",
    content: str = "",
    media_type: str = "text",
    media_path: Optional[str] = None,
    transcript: Optional[str] = None,
    mood: Optional[str] = None,
    tags: list[str] = None,
) -> dict:
    db = await get_db()
    entry_id = _new_id()
    now = _now()
    tags_json = json.dumps(tags or [])
    await db.execute(
        "INSERT INTO entries (id, title, content, media_type, media_path, transcript, mood, tags, created_at, updated_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (entry_id, title, content, media_type, media_path, transcript, mood, tags_json, now, now),
    )
    await db.commit()
    row = await db.execute_fetchall("SELECT * FROM entries WHERE id = ?", (entry_id,))
    await db.close()
    return dict(row[0])


async def list_entries(limit: int = 100, offset: int = 0) -> list[dict]:
    db = await get_db()
    rows = await db.execute_fetchall(
        "SELECT * FROM entries ORDER BY created_at DESC LIMIT ? OFFSET ?", (limit, offset)
    )
    await db.close()
    return [dict(r) for r in rows]


async def get_entry(entry_id: str) -> Optional[dict]:
    db = await get_db()
    rows = await db.execute_fetchall("SELECT * FROM entries WHERE id = ?", (entry_id,))
    await db.close()
    return dict(rows[0]) if rows else None


async def update_entry(entry_id: str, **fields: Any) -> Optional[dict]:
    db = await get_db()
    allowed = {"title", "content", "transcript", "mood", "tags", "processed", "media_type", "media_path"}
    updates = {k: v for k, v in fields.items() if k in allowed and v is not None}
    if not updates:
        await db.close()
        return await get_entry(entry_id)
    if "tags" in updates and isinstance(updates["tags"], list):
        updates["tags"] = json.dumps(updates["tags"])
    updates["updated_at"] = _now()
    set_clause = ", ".join(f"{k} = ?" for k in updates)
    values = list(updates.values()) + [entry_id]
    await db.execute(f"UPDATE entries SET {set_clause} WHERE id = ?", values)
    await db.commit()
    await db.close()
    return await get_entry(entry_id)


async def delete_entry(entry_id: str) -> bool:
    db = await get_db()
    await db.execute("DELETE FROM entries WHERE id = ?", (entry_id,))
    await db.commit()
    await db.close()
    return True


async def create_insight(
    type: str,
    content: str,
    empathy_score: float = 0.8,
    related_memory_ids: list[str] = None,
) -> dict:
    db = await get_db()
    insight_id = _new_id()
    now = _now()
    await db.execute(
        "INSERT INTO insights (id, type, content, empathy_score, related_memory_ids, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (insight_id, type, content, empathy_score, json.dumps(related_memory_ids or []), now),
    )
    await db.commit()
    rows = await db.execute_fetchall("SELECT * FROM insights WHERE id = ?", (insight_id,))
    await db.close()
    return dict(rows[0])


async def list_insights(unread_only: bool = False, limit: int = 50) -> list[dict]:
    db = await get_db()
    query = "SELECT * FROM insights"
    if unread_only:
        query += " WHERE read = 0"
    query += " ORDER BY created_at DESC LIMIT ?"
    rows = await db.execute_fetchall(query, (limit,))
    await db.close()
    return [dict(r) for r in rows]


async def mark_insight_read(insight_id: str) -> Optional[dict]:
    db = await get_db()
    await db.execute("UPDATE insights SET read = 1, delivered = 1 WHERE id = ?", (insight_id,))
    await db.commit()
    rows = await db.execute_fetchall("SELECT * FROM insights WHERE id = ?", (insight_id,))
    await db.close()
    return dict(rows[0]) if rows else None


async def count_insights_today() -> int:
    db = await get_db()
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    rows = await db.execute_fetchall(
        "SELECT COUNT(*) as cnt FROM insights WHERE created_at LIKE ?", (f"{today}%",)
    )
    await db.close()
    return rows[0]["cnt"]
