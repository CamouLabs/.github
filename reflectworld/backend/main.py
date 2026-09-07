from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.entries import router as entries_router
from api.insights import router as insights_router
from api.media import router as media_router
from api.memory import router as memory_router
from database import get_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    db = await get_db()
    await db.close()
    yield


app = FastAPI(
    title="ReflectWorld",
    description="A compassionate world model for your inner life",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(entries_router)
app.include_router(media_router)
app.include_router(memory_router)
app.include_router(insights_router)


@app.get("/api/health")
async def health():
    from config import settings
    return {
        "status": "ok",
        "llm_available": bool(settings.openai_api_key),
    }
