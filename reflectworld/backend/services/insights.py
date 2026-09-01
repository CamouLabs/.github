import json
import logging
from datetime import datetime, timezone

from database import count_insights_today, create_insight, list_insights
from services.memory_graph import get_memory_graph
from services.pipeline import _generate_insight, _extract_entities

logger = logging.getLogger(__name__)


async def generate_insights() -> list[dict]:
    if await count_insights_today() >= 3:
        return []

    graph = get_memory_graph()
    nodes = graph.get_all_nodes()
    reflective = [n for n in nodes if n["tier"] == "reflective"]

    if len(reflective) < 2:
        return []

    created = []
    # Find clusters of related reflective memories
    for node in reflective[-5:]:
        related = graph.search(node["content"], top_k=3)
        cross_refs = [r for r in related if r["node_id"] != node["id"] and r["score"] > 0.4]

        if cross_refs and await count_insights_today() < 3:
            entities = await _extract_entities(node["content"])
            insight = await _generate_insight(
                node["content"], entities, cross_refs, node["content"]
            )
            if insight:
                result = await create_insight(
                    type=insight["type"],
                    content=insight["content"],
                    empathy_score=insight.get("empathy_score", 0.8),
                    related_memory_ids=[node["id"]],
                )
                created.append(result)

    return created
