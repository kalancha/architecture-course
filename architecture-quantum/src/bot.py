import re
from typing import Optional

from src.embeddings import BaseEmbedder, SentenceTransformerEmbedder
from src.vectorstore import VectorStore
from src.llm import BaseLLM, create_default_llm
from src.prompt import build_prompt, build_system_prompt
from src.config import TOP_K, ROUTE_NON_QUESTIONS_DIRECT
from src.security import DefenseConfig, looks_malicious, sanitize_chunk


_QUESTION_START_WORDS = (
    # RU
    "кто",
    "что",
    "где",
    "когда",
    "почему",
    "зачем",
    "как",
    "какой",
    "какая",
    "какие",
    "сколько",
    "куда",
    "откуда",
    "можно ли",
    "нужно ли",
    "правда ли",
    # EN
    "what",
    "why",
    "how",
    "who",
    "when",
    "where",
    "which",
    "can",
    "could",
    "should",
    "is",
    "are",
    "do",
    "does",
    "did",
)

_KNOWLEDGE_REQUEST_VERBS = (
    # Common imperatives that are still “knowledge queries”
    "расскажи",
    "объясни",
    "опиши",
    "поясни",
    "перечисли",
    "сравни",
    "подскажи",
    "найди",
    "покажи",
)

_ACTION_VERBS_DIRECT = (
    # Requests that are usually "do something" rather than "lookup in KB"
    "сделай",
    "напиши",
    "переведи",
    "сгенерируй",
    "придумай",
    "сократи",
    "суммаризируй",
    "исправь",
    "улучши",
    # EN
    "write",
    "generate",
    "translate",
    "summarize",
    "fix",
    "improve",
)


def _looks_like_knowledge_query(text: str) -> bool:
    raw = text.strip()
    t = raw.lower()
    if not t:
        return False

    # Fast path: question mark anywhere
    if "?" in t:
        return True

    # Strip leading punctuation/quotes/markdown markers
    raw2 = re.sub(r"^[\s\-\*\>\(\)\[\]\"'`]+", "", raw).strip()
    t2 = raw2.lower()

    for w in _QUESTION_START_WORDS:
        if t2 == w or t2.startswith(w + " "):
            return True

    for v in _KNOWLEDGE_REQUEST_VERBS:
        if t2 == v or t2.startswith(v + " "):
            return True

    # Treat "topic/keyword" inputs as knowledge queries (e.g. entity names, article titles)
    if raw2:
        # But route obvious action requests directly to LLM
        for a in _ACTION_VERBS_DIRECT:
            if t2 == a or t2.startswith(a + " "):
                return False

        parts = [p for p in re.split(r"\s+", raw2) if p]
        if len(parts) >= 2 and len(raw2) <= 120:
            return True

        if len(parts) == 1:
            token = parts[0]
            # Single-token topics like "Silverwolf" / "Galfridus" should use RAG
            if (token[:1].isupper() and len(token) >= 4) or any(ch.isdigit() for ch in token):
                return True

    return False


class RAGBot:
    def __init__(
        self,
        embedder: Optional[BaseEmbedder] = None,
        llm: Optional[BaseLLM] = None,
        top_k: int = TOP_K,
        route_non_questions_direct: bool = ROUTE_NON_QUESTIONS_DIRECT,
        defense: Optional[DefenseConfig] = None,
    ):
        self._embedder = embedder or SentenceTransformerEmbedder()
        self._vector_store = VectorStore(self._embedder)
        self._llm = llm or create_default_llm()
        self._top_k = top_k
        self._route_non_questions_direct = route_non_questions_direct
        self._defense = defense or DefenseConfig.from_level("all")

    @property
    def vector_store(self) -> VectorStore:
        return self._vector_store

    @property
    def defense(self) -> DefenseConfig:
        return self._defense

    def ask(self, question: str) -> str:
        system_prompt = build_system_prompt(self._defense.pre_prompt)

        if self._route_non_questions_direct and not _looks_like_knowledge_query(question):
            return self._llm.generate(
                [
                    {"role": "system", "text": system_prompt},
                    {"role": "user", "text": question},
                ]
            )

        relevant_chunks = self._vector_store.search(question, top_k=self._top_k)

        if not relevant_chunks:
            return "Knowledge base is empty. Please index documents first."

        chunks = relevant_chunks
        if self._defense.chunk_filter:
            chunks = [c for c in chunks if not looks_malicious(c)]
        if self._defense.sanitize:
            chunks = [sanitize_chunk(c) for c in chunks]
            chunks = [c for c in chunks if c.strip()]

        if not chunks:
            return "У меня нет достаточной информации."

        prompt = build_prompt(question, chunks)
        answer = self._llm.generate(
            [
                {"role": "system", "text": system_prompt},
                {"role": "user", "text": prompt},
            ]
        )
        return answer
