import shutil

from src.bot import RAGBot
from src.config import CHROMA_PERSIST_DIR
from src.indexer import build_index


def main() -> None:
    if CHROMA_PERSIST_DIR.exists():
        for child in CHROMA_PERSIST_DIR.iterdir():
            if child.is_dir():
                shutil.rmtree(child)
            else:
                child.unlink()

    bot = RAGBot()
    count = build_index(bot.vector_store)
    print(f"Built ChromaDB index with {count} chunks.")


if __name__ == "__main__":
    main()
