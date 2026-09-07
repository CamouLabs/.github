import logging
from typing import Optional

logger = logging.getLogger(__name__)

_model = None


def _get_model():
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer
        from config import settings

        _model = SentenceTransformer(settings.embedding_model)
    return _model


def embed_text(text: str) -> list[float]:
    model = _get_model()
    return model.encode(text, normalize_embeddings=True).tolist()


def embed_texts(texts: list[str]) -> list[list[float]]:
    model = _get_model()
    return model.encode(texts, normalize_embeddings=True).tolist()


def cosine_similarity(a: list[float], b: list[float]) -> float:
    import numpy as np

    va, vb = np.array(a), np.array(b)
    dot = np.dot(va, vb)
    norm = np.linalg.norm(va) * np.linalg.norm(vb)
    return float(dot / norm) if norm > 0 else 0.0


def search_similar(query: str, candidates: list[dict], top_k: int = 5) -> list[dict]:
    if not candidates:
        return []
    query_emb = embed_text(query)
    scored = []
    for c in candidates:
        if c.get("embedding"):
            score = cosine_similarity(query_emb, c["embedding"])
            scored.append({**c, "score": score})
    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored[:top_k]
