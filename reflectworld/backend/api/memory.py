from fastapi import APIRouter, Query

from models.schemas import GraphResponse, MemoryEdge, MemoryNode, SearchResult
from services.memory_graph import get_memory_graph

router = APIRouter(prefix="/api/memory", tags=["memory"])


@router.get("/graph", response_model=GraphResponse)
async def get_graph():
    graph = get_memory_graph()
    nodes = [MemoryNode(**n) for n in graph.get_all_nodes()]
    edges = [MemoryEdge(**e) for e in graph.get_all_edges()]
    return GraphResponse(nodes=nodes, edges=edges)


@router.get("/search", response_model=list[SearchResult])
async def search_memories(q: str = Query(..., min_length=1), top_k: int = 10):
    graph = get_memory_graph()
    results = graph.search(q, top_k=top_k)
    return [SearchResult(**r) for r in results]


@router.post("/consolidate")
async def consolidate_memories():
    graph = get_memory_graph()
    graph.consolidate()
    return {"ok": True, "nodes": len(graph.get_all_nodes())}
