from typing import List, Dict, Any, Optional

import chromadb
from chromadb.config import Settings

from src.config import CHROMA_PERSIST_DIR, TOP_K
from src.embeddings import BaseEmbedder


COLLECTION_NAME = "knowledge_base"


class VectorStore:
    def __init__(self, embedder: BaseEmbedder):
        self._embedder = embedder
        self._client = chromadb.PersistentClient(
            path=str(CHROMA_PERSIST_DIR),
            settings=Settings(anonymized_telemetry=False),
        )
        self._collection = self._client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"},
        )

    @property
    def count(self) -> int:
        return self._collection.count()

    def add_documents(self, chunks: List[str], metadatas: Optional[List[Dict[str, Any]]] = None) -> None:
        embeddings = self._embedder.embed(chunks)
        ids = [f"chunk_{self.count + i}" for i in range(len(chunks))]
        self._collection.add(
            ids=ids,
            embeddings=embeddings,
            documents=chunks,
            metadatas=metadatas,
        )

    def search(self, query: str, top_k: int = TOP_K) -> List[str]:
        query_embedding = self._embedder.embed([query])[0]
        results = self._collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k,
        )
        documents = results.get("documents", [[]])[0]
        return documents

    def reset(self) -> None:
        self._client.delete_collection(COLLECTION_NAME)
        self._collection = self._client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"},
        )
