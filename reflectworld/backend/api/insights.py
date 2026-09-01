import json

from fastapi import APIRouter

from database import list_insights, mark_insight_read
from models.schemas import InsightResponse
from services.insights import generate_insights

router = APIRouter(prefix="/api/insights", tags=["insights"])


def _parse_insight(row: dict) -> dict:
    ids = row.get("related_memory_ids", "[]")
    if isinstance(ids, str):
        ids = json.loads(ids)
    return {**row, "related_memory_ids": ids}


@router.get("", response_model=list[InsightResponse])
async def list_insights_endpoint(unread_only: bool = False):
    rows = await list_insights(unread_only=unread_only)
    return [_parse_insight(r) for r in rows]


@router.post("/generate")
async def generate_insights_endpoint():
    created = await generate_insights()
    return {"created": len(created), "insights": [_parse_insight(c) for c in created]}


@router.post("/{insight_id}/read", response_model=InsightResponse)
async def mark_read(insight_id: str):
    result = await mark_insight_read(insight_id)
    if not result:
        from fastapi import HTTPException
        raise HTTPException(404, "Insight not found")
    return _parse_insight(result)
