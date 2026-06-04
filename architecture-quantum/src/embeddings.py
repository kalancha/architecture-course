from abc import ABC, abstractmethod
from typing import List

from sentence_transformers import SentenceTransformer

from src.config import EMBEDDING_MODEL_NAME


class BaseEmbedder(ABC):
    @abstractmethod
    def embed(self, texts: List[str]) -> List[List[float]]:
        ...


class SentenceTransformerEmbedder(BaseEmbedder):
    def __init__(self, model_name: str = EMBEDDING_MODEL_NAME):
        self._model = SentenceTransformer(model_name)

    def embed(self, texts: List[str]) -> List[List[float]]:
        embeddings = self._model.encode(texts, show_progress_bar=False)
        return embeddings.tolist()
