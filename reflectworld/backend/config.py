from pathlib import Path
from pydantic_settings import BaseSettings

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
UPLOADS_DIR = DATA_DIR / "uploads"
GRAPH_FILE = DATA_DIR / "memory_graph.json"

DATA_DIR.mkdir(parents=True, exist_ok=True)
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)


class Settings(BaseSettings):
    openai_api_key: str = ""
    whisper_model: str = "base"
    embedding_model: str = "all-MiniLM-L6-v2"
    max_upload_mb: int = 100
    max_insights_per_day: int = 3
    backend_port: int = 8000
    frontend_port: int = 3000

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()

ALLOWED_EXTENSIONS = {".mp3", ".wav", ".m4a", ".ogg", ".webm", ".mp4", ".mov", ".avi", ".mkv"}
