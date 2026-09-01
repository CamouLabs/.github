"""Seed demo data for ReflectWorld."""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from database import create_entry, get_db
from services.pipeline import process_entry


DEMO_ENTRIES = [
    {
        "title": "Morning gratitude",
        "content": "Woke up early and watched the sunrise. Felt grateful for quiet mornings. "
        "I've been thinking about starting a meditation practice. My body feels rested today.",
        "mood": "grateful",
    },
    {
        "title": "Work anxiety",
        "content": "Had a tough meeting today. My boss questioned the project timeline and I felt anxious. "
        "I know I'm capable but the pressure is real. Need to talk to my colleague James about this.",
        "mood": "anxious",
    },
    {
        "title": "Weekend plans",
        "content": "Planning to visit my parents this weekend. Mom has been asking me to come. "
        "I feel a mix of excitement and guilt — I should have visited sooner. "
        "Want to bring them something special.",
        "mood": "hopeful",
    },
]


async def seed():
    db = await get_db()
    await db.close()

    for demo in DEMO_ENTRIES:
        entry = await create_entry(
            title=demo["title"],
            content=demo["content"],
            mood=demo["mood"],
            media_type="text",
        )
        print(f"Created: {entry['title']}")
        result = await process_entry(entry["id"])
        print(f"  → {result.get('nodes_created', 0)} nodes, {result.get('insights_created', 0)} insights")

    print("Demo data seeded successfully.")


if __name__ == "__main__":
    asyncio.run(seed())
