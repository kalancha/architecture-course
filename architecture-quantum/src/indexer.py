from pathlib import Path
import re
from typing import Any, Dict, List, Tuple

from src.config import KNOWLEDGE_BASE_DIR, CHUNK_SIZE_WORDS, CHUNK_OVERLAP_WORDS
from src.vectorstore import VectorStore


SUPPORTED_EXTENSIONS = {".txt", ".md", ".csv", ".json"}


def _extract_title(file_path: Path, text: str) -> str:
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("#"):
            return line.lstrip("#").strip()
    return file_path.stem.replace("-", " ").replace("_", " ").title()


def load_documents(directory: Path = KNOWLEDGE_BASE_DIR) -> List[Tuple[Path, str, str]]:
    documents: List[Tuple[Path, str, str]] = []
    for file_path in directory.rglob("*"):
        if file_path.suffix.lower() in SUPPORTED_EXTENSIONS:
            text = file_path.read_text(encoding="utf-8")
            documents.append((file_path, _extract_title(file_path, text), text))
    return documents


def split_into_chunks(
    text: str,
    chunk_size_words: int = CHUNK_SIZE_WORDS,
    overlap_words: int = CHUNK_OVERLAP_WORDS,
) -> List[str]:
    words = re.findall(r"\S+", text)
    if not words:
        return []

    chunks: List[str] = []
    step = max(1, chunk_size_words - overlap_words)
    for start in range(0, len(words), step):
        chunk_words = words[start : start + chunk_size_words]
        chunk = " ".join(chunk_words)
        if chunk.strip():
            chunks.append(chunk.strip())
    return chunks


def build_index(vector_store: VectorStore, directory: Path = KNOWLEDGE_BASE_DIR) -> int:
    documents = load_documents(directory)
    if not documents:
        print(f"[indexer] No documents found in {directory}")
        return 0

    all_chunks: List[str] = []
    metadatas: List[Dict[str, Any]] = []
    for file_path, title, doc in documents:
        chunks = split_into_chunks(doc)
        for chunk_index, chunk in enumerate(chunks):
            all_chunks.append(chunk)
            metadatas.append(
                {
                    "source_path": str(file_path.relative_to(directory.parent)),
                    "title": title,
                    "chunk_id": f"{file_path.stem}:{chunk_index}",
                    "chunk_index": chunk_index,
                }
            )

    if all_chunks:
        vector_store.add_documents(all_chunks, metadatas=metadatas)

    print(f"[indexer] Indexed {len(all_chunks)} chunks from {len(documents)} documents")
    return len(all_chunks)
