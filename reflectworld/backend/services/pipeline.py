import json
import logging
import re
from typing import Optional

from config import settings
from database import create_insight, count_insights_today, get_entry, update_entry
from services.memory_graph import get_memory_graph

logger = logging.getLogger(__name__)

EMOTION_WORDS = {
    "happy": 0.8, "joy": 0.9, "excited": 0.7, "grateful": 0.8, "peaceful": 0.7,
    "sad": 0.7, "anxious": 0.6, "worried": 0.5, "angry": 0.6, "frustrated": 0.5,
    "overwhelmed": 0.7, "tired": 0.4, "hopeful": 0.8, "proud": 0.8, "lonely": 0.6,
    "content": 0.7, "stressed": 0.5, "calm": 0.7, "loving": 0.9, "scared": 0.6,
}

THEME_PATTERNS = {
    "work": r"\b(work|job|career|boss|colleague|meeting|project)\b",
    "family": r"\b(family|mom|dad|parent|sibling|child|partner|spouse)\b",
    "health": r"\b(health|exercise|sleep|tired|energy|walk|run|gym)\b",
    "creativity": r"\b(create|art|write|music|design|build|idea)\b",
    "relationships": r"\b(friend|relationship|love|connect|social|talk)\b",
    "growth": r"\b(learn|grow|improve|change|progress|goal|habit)\b",
    "nature": r"\b(nature|outdoor|garden|tree|sky|sun|rain)\b",
}


def _llm_available() -> bool:
    return bool(settings.openai_api_key)


async def _call_llm(prompt: str, system: str = "") -> Optional[str]:
    if not _llm_available():
        return None
    try:
        import litellm

        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})
        response = await litellm.acompletion(
            model="gpt-4o-mini",
            messages=messages,
            api_key=settings.openai_api_key,
            max_tokens=500,
        )
        return response.choices[0].message.content
    except Exception as e:
        logger.error("LLM call failed: %s", e)
        return None


def _extract_entities_rule_based(text: str) -> dict:
    text_lower = text.lower()
    emotions = []
    for word, weight in EMOTION_WORDS.items():
        if word in text_lower:
            emotions.append({"word": word, "weight": weight})

    themes = []
    for theme, pattern in THEME_PATTERNS.items():
        if re.search(pattern, text_lower):
            themes.append(theme)

    segments = []
    sentences = re.split(r'[.!?]+', text)
    for i, sent in enumerate(sentences):
        sent = sent.strip()
        if len(sent) > 10:
            segments.append({"index": i, "text": sent})

    return {
        "emotions": emotions,
        "themes": themes,
        "segments": segments,
    }


async def _extract_entities(text: str) -> dict:
    if _llm_available():
        result = await _call_llm(
            f"Extract from this journal entry:\n{text}\n\n"
            "Return JSON with: emotions (list of strings), themes (list of strings), "
            "key_events (list of short descriptions), people (list of names mentioned).",
            system="You are a compassionate journal analyst. Extract entities without judgment. Return valid JSON only.",
        )
        if result:
            try:
                cleaned = result.strip()
                if cleaned.startswith("```"):
                    cleaned = cleaned.split("\n", 1)[1].rsplit("```", 1)[0]
                return json.loads(cleaned)
            except json.JSONDecodeError:
                pass
    return _extract_entities_rule_based(text)


async def _condense(text: str, entities: dict, graph_context: list[dict]) -> str:
    context_str = ""
    if graph_context:
        context_str = "Related past memories:\n" + "\n".join(f"- {m['content']}" for m in graph_context[:3])

    if _llm_available():
        result = await _call_llm(
            f"Condense this journal entry into a single reflective memory (2-3 sentences):\n{text}\n\n"
            f"Entities: {json.dumps(entities)}\n{context_str}\n\n"
            "Focus on feelings, growth, and what matters. Be gentle.",
            system="You create condensed memory representations for a personal journal. "
            "Write in second person ('you'). Be empathic and non-judgmental.",
        )
        if result:
            return result.strip()

    emotions = entities.get("emotions", [])
    themes = entities.get("themes", [])
    emotion_str = ", ".join(
        e.get("word", e) if isinstance(e, dict) else e for e in emotions[:3]
    ) or "reflective"
    theme_str = ", ".join(themes[:3]) or "personal"
    snippet = text[:150] + ("..." if len(text) > 150 else "")
    return f"You reflected on {theme_str}, feeling {emotion_str}. {snippet}"


async def process_entry(entry_id: str) -> dict:
    entry = await get_entry(entry_id)
    if not entry:
        return {"error": "Entry not found"}

    text = entry.get("transcript") or entry.get("content") or ""
    if not text.strip():
        return {"error": "No content to process"}

    graph = get_memory_graph()
    nodes_created = 0
    edges_created = 0
    insights_created = 0

    # Stage 1: Extract
    entities = await _extract_entities(text)

    # Stage 2: Condense — search for related memories
    related = graph.search(text[:200], top_k=3)
    condensed = await _condense(text, entities, related)

    emotional_weight = 0.0
    for e in entities.get("emotions", []):
        w = e.get("weight", 0.5) if isinstance(e, dict) else 0.5
        emotional_weight = max(emotional_weight, w)

    # Create perceptual nodes for segments
    segments = entities.get("segments", [])
    segment_node_ids = []
    for seg in segments[:5]:
        seg_text = seg.get("text", "") if isinstance(seg, dict) else str(seg)
        if seg_text:
            node = graph.add_node(
                content=seg_text,
                tier="perceptual",
                entity_type="event",
                source_entry_id=entry_id,
                salience=0.3,
                emotional_weight=emotional_weight * 0.5,
            )
            segment_node_ids.append(node["id"])
            nodes_created += 1

    # Create reflective condensed node
    reflective_node = graph.add_node(
        content=condensed,
        tier="reflective",
        entity_type="insight",
        source_entry_id=entry_id,
        salience=0.5 + emotional_weight * 0.3,
        emotional_weight=emotional_weight,
    )
    nodes_created += 1

    # Link segments to reflective node
    for seg_id in segment_node_ids:
        graph.add_edge(seg_id, reflective_node["id"], "evolved_from", 0.7)
        edges_created += 1

    # Create theme nodes
    for theme in entities.get("themes", [])[:5]:
        theme_name = theme if isinstance(theme, str) else str(theme)
        theme_node = graph.add_node(
            content=f"Theme: {theme_name}",
            tier="perceptual",
            entity_type="theme",
            source_entry_id=entry_id,
            salience=0.4,
        )
        graph.add_edge(reflective_node["id"], theme_node["id"], "related_to", 0.6)
        nodes_created += 1
        edges_created += 1

    # Link to related past memories
    for rel in related:
        if rel["score"] > 0.5:
            graph.add_edge(reflective_node["id"], rel["node_id"], "reminds_of", rel["score"])
            edges_created += 1

    # Stage 3: Reflect — generate insights
    if await count_insights_today() < settings.max_insights_per_day:
        insight = await _generate_insight(text, entities, related, condensed)
        if insight:
            await create_insight(
                type=insight["type"],
                content=insight["content"],
                empathy_score=insight.get("empathy_score", 0.8),
                related_memory_ids=[reflective_node["id"]],
            )
            insights_created += 1

    graph.consolidate()
    await update_entry(entry_id, processed=1)

    return {
        "entry_id": entry_id,
        "nodes_created": nodes_created,
        "edges_created": edges_created,
        "insights_created": insights_created,
        "transcript": entry.get("transcript"),
    }


async def _generate_insight(
    text: str, entities: dict, related: list, condensed: str
) -> Optional[dict]:
    if _llm_available():
        related_str = "\n".join(f"- {r['content']}" for r in related[:3]) if related else "No related memories yet."
        result = await _call_llm(
            f"Based on this journal entry and context, generate ONE gentle insight.\n\n"
            f"Entry: {text[:500]}\n\nCondensed: {condensed}\n\nPast related memories:\n{related_str}\n\n"
            "Return JSON: {\"type\": \"reminder|pattern|encouragement|reflection_question\", "
            "\"content\": \"your insight\", \"empathy_score\": 0.0-1.0}\n\n"
            "Rules: Never judge. Use 'It seems like...' or 'You might notice...'. "
            "Prefer reflection questions. Celebrate growth.",
            system="You are an empathic journal companion. Generate gentle, non-judgmental insights.",
        )
        if result:
            try:
                cleaned = result.strip()
                if cleaned.startswith("```"):
                    cleaned = cleaned.split("\n", 1)[1].rsplit("```", 1)[0]
                return json.loads(cleaned)
            except json.JSONDecodeError:
                pass

    # Rule-based fallback
    emotions = entities.get("emotions", [])
    themes = entities.get("themes", [])

    if related and related[0]["score"] > 0.6:
        return {
            "type": "pattern",
            "content": f"It seems like this connects to something you've reflected on before — "
            f"about {related[0]['content'][:80]}. Patterns like this can reveal what truly matters to you.",
            "empathy_score": 0.85,
        }

    if emotions:
        em = emotions[0]
        word = em.get("word", em) if isinstance(em, dict) else em
        return {
            "type": "reflection_question",
            "content": f"You mentioned feeling {word}. What would it feel like to sit with that feeling "
            "for a moment, without needing to change it?",
            "empathy_score": 0.8,
        }

    if themes:
        theme = themes[0] if isinstance(themes[0], str) else str(themes[0])
        return {
            "type": "encouragement",
            "content": f"Taking time to reflect on {theme} shows real self-awareness. "
            "That kind of honesty with yourself is a gift.",
            "empathy_score": 0.85,
        }

    return {
        "type": "reflection_question",
        "content": "What stood out to you most as you wrote this? Sometimes the first thing we mention "
        "holds more meaning than we realize.",
        "empathy_score": 0.75,
    }
