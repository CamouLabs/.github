import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Optional

import networkx as nx

from config import GRAPH_FILE
from services.embeddings import embed_text, search_similar

logger = logging.getLogger(__name__)


class MemoryGraph:
    def __init__(self):
        self.graph = nx.DiGraph()
        self._node_data: dict[str, dict] = {}
        self._load()

    def _load(self):
        if GRAPH_FILE.exists():
            try:
                data = json.loads(GRAPH_FILE.read_text())
                for node in data.get("nodes", []):
                    self._node_data[node["id"]] = node
                    self.graph.add_node(node["id"])
                for edge in data.get("edges", []):
                    self.graph.add_edge(
                        edge["source_id"],
                        edge["target_id"],
                        relationship=edge["relationship"],
                        weight=edge.get("weight", 0.5),
                    )
            except Exception as e:
                logger.error("Failed to load graph: %s", e)

    def _save(self):
        nodes = list(self._node_data.values())
        edges = []
        for u, v, data in self.graph.edges(data=True):
            edges.append({
                "source_id": u,
                "target_id": v,
                "relationship": data.get("relationship", "related_to"),
                "weight": data.get("weight", 0.5),
            })
        GRAPH_FILE.write_text(json.dumps({"nodes": nodes, "edges": edges}, indent=2))

    def _now(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    def add_node(
        self,
        content: str,
        tier: str = "perceptual",
        entity_type: str = "theme",
        source_entry_id: Optional[str] = None,
        salience: float = 0.5,
        emotional_weight: float = 0.0,
    ) -> dict:
        node_id = str(uuid.uuid4())
        now = self._now()
        embedding = embed_text(content)
        node = {
            "id": node_id,
            "tier": tier,
            "content": content,
            "salience": salience,
            "sticky_score": emotional_weight,
            "source_entry_id": source_entry_id,
            "entity_type": entity_type,
            "created_at": now,
            "last_accessed": now,
            "access_count": 0,
            "embedding": embedding,
        }
        self._node_data[node_id] = node
        self.graph.add_node(node_id)
        self._save()
        return {k: v for k, v in node.items() if k != "embedding"}

    def add_edge(self, source_id: str, target_id: str, relationship: str = "related_to", weight: float = 0.5):
        if source_id in self._node_data and target_id in self._node_data:
            self.graph.add_edge(source_id, target_id, relationship=relationship, weight=weight)
            self._save()

    def get_node(self, node_id: str) -> Optional[dict]:
        node = self._node_data.get(node_id)
        if node:
            self._touch(node_id)
            return {k: v for k, v in node.items() if k != "embedding"}
        return None

    def _touch(self, node_id: str):
        node = self._node_data.get(node_id)
        if node:
            node["access_count"] += 1
            node["last_accessed"] = self._now()
            node["sticky_score"] = min(1.0, node["sticky_score"] + 0.1 * (1 - node["sticky_score"]))
            self._save()

    def search(self, query: str, top_k: int = 10) -> list[dict]:
        candidates = list(self._node_data.values())
        results = search_similar(query, candidates, top_k)
        for r in results:
            self._touch(r["id"])
        return [
            {
                "node_id": r["id"],
                "content": r["content"],
                "score": r["score"],
                "tier": r["tier"],
                "entity_type": r["entity_type"],
            }
            for r in results
        ]

    def get_all_nodes(self) -> list[dict]:
        return [{k: v for k, v in n.items() if k != "embedding"} for n in self._node_data.values()]

    def get_all_edges(self) -> list[dict]:
        edges = []
        for u, v, data in self.graph.edges(data=True):
            edges.append({
                "source_id": u,
                "target_id": v,
                "relationship": data.get("relationship", "related_to"),
                "weight": data.get("weight", 0.5),
            })
        return edges

    def find_similar_nodes(self, content: str, threshold: float = 0.85) -> list[dict]:
        results = self.search(content, top_k=5)
        return [r for r in results if r["score"] >= threshold]

    def consolidate(self):
        """Merge similar episodic nodes and promote high-salience nodes to reflective tier."""
        perceptual = [n for n in self._node_data.values() if n["tier"] == "perceptual"]
        merged = set()

        for i, node_a in enumerate(perceptual):
            if node_a["id"] in merged:
                continue
            similar = self.find_similar_nodes(node_a["content"], threshold=0.85)
            for sim in similar:
                if sim["node_id"] != node_a["id"] and sim["node_id"] not in merged:
                    target = self._node_data.get(sim["node_id"])
                    if target and target["tier"] == "perceptual":
                        node_a["content"] = f"{node_a['content']} | {target['content']}"
                        node_a["salience"] = max(node_a["salience"], target["salience"])
                        node_a["sticky_score"] = max(node_a["sticky_score"], target["sticky_score"])
                        node_a["embedding"] = embed_text(node_a["content"])
                        merged.add(target["id"])
                        self.graph.remove_node(target["id"])
                        del self._node_data[target["id"]]

        for node in self._node_data.values():
            if node["tier"] == "perceptual" and node["sticky_score"] > 0.6:
                node["tier"] = "reflective"
                node["salience"] = min(1.0, node["salience"] + 0.2)

        self._save()


_memory_graph: Optional[MemoryGraph] = None


def get_memory_graph() -> MemoryGraph:
    global _memory_graph
    if _memory_graph is None:
        _memory_graph = MemoryGraph()
    return _memory_graph
