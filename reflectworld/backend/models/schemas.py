from typing import Optional
from pydantic import BaseModel, Field


class EntryCreate(BaseModel):
    title: str = ""
    content: str = ""
    media_type: str = "text"
    mood: Optional[str] = None
    tags: list[str] = Field(default_factory=list)


class EntryUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    transcript: Optional[str] = None
    mood: Optional[str] = None
    tags: Optional[list[str]] = None


class EntryResponse(BaseModel):
    id: str
    title: str
    content: str
    media_type: str
    media_path: Optional[str] = None
    transcript: Optional[str] = None
    mood: Optional[str] = None
    tags: list[str] = []
    created_at: str
    updated_at: str
    processed: int = 0


class MemoryNode(BaseModel):
    id: str
    tier: str
    content: str
    salience: float = 0.5
    sticky_score: float = 0.0
    source_entry_id: Optional[str] = None
    entity_type: str = "theme"
    created_at: str
    last_accessed: str
    access_count: int = 0


class MemoryEdge(BaseModel):
    source_id: str
    target_id: str
    relationship: str
    weight: float = 0.5


class GraphResponse(BaseModel):
    nodes: list[MemoryNode]
    edges: list[MemoryEdge]


class InsightResponse(BaseModel):
    id: str
    type: str
    content: str
    empathy_score: float
    related_memory_ids: list[str] = []
    created_at: str
    delivered: int = 0
    read: int = 0


class SearchResult(BaseModel):
    node_id: str
    content: str
    score: float
    tier: str
    entity_type: str


class ProcessResult(BaseModel):
    entry_id: str
    nodes_created: int
    edges_created: int
    insights_created: int
    transcript: Optional[str] = None
