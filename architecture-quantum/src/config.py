import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

try:
    from dotenv import load_dotenv  # type: ignore

    load_dotenv(PROJECT_ROOT / ".env")
except ImportError:
    # Optional dependency; env vars can be provided by the shell instead of a .env file.
    pass

KNOWLEDGE_BASE_DIR = PROJECT_ROOT / "knowledge_base"
CHROMA_PERSIST_DIR = PROJECT_ROOT / "chroma_db"

CHUNK_SIZE_WORDS = 220
CHUNK_OVERLAP_WORDS = 40

EMBEDDING_MODEL_NAME = os.getenv(
    "EMBEDDING_MODEL_NAME",
    # Better default for RU+EN queries against mixed-language knowledge base
    "paraphrase-multilingual-MiniLM-L12-v2",
)

TOP_K = 5

# Routing: if message does NOT look like a knowledge question/request,
# bypass retrieval and send directly to LLM.
#
# Default is OFF: route everything through retrieval (RAG).
ROUTE_NON_QUESTIONS_DIRECT = os.getenv("ROUTE_NON_QUESTIONS_DIRECT", "0").strip() not in (
    "0",
    "false",
    "False",
    "no",
    "NO",
)

# YandexGPT
YANDEX_API_KEY = os.getenv("YANDEX_API_KEY")
YANDEX_FOLDER_ID = os.getenv("YANDEX_FOLDER_ID")
YANDEX_API_URL = os.getenv("YANDEX_API_URL", "https://llm.api.cloud.yandex.net/foundationModels/v1/completion")
YANDEX_MODEL_URI = os.getenv("YANDEX_MODEL_URI")  # optional override
YANDEX_MODEL = os.getenv("YANDEX_MODEL", "yandexgpt-lite")
YANDEX_TEMPERATURE = float(os.getenv("YANDEX_TEMPERATURE", "0.6"))
YANDEX_MAX_TOKENS = int(os.getenv("YANDEX_MAX_TOKENS", "2000"))
YANDEX_TIMEOUT_S = float(os.getenv("YANDEX_TIMEOUT_S", "60"))
