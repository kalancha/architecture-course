import argparse
import os

from src.bot import RAGBot
from src.indexer import build_index
from src.security import DefenseConfig


def main() -> None:
    parser = argparse.ArgumentParser(description="Console RAG bot (Chroma + embeddings + LLM)")
    parser.add_argument("--index", action="store_true", help="Rebuild index from knowledge_base/ (resets collection)")
    parser.add_argument(
        "--defense",
        choices=["none", "pre", "filter", "sanitize", "all"],
        default=os.getenv("DEFENSE_LEVEL", "all"),
        help="Prompt-injection defense level",
    )
    args = parser.parse_args()

    print("Initializing RAG bot...")
    bot = RAGBot(defense=DefenseConfig.from_level(args.defense))
    print(f"Defense: {args.defense} (pre={bot.defense.pre_prompt}, filter={bot.defense.chunk_filter}, sanitize={bot.defense.sanitize})")

    if args.index:
        if bot.vector_store.count > 0:
            print("Resetting existing vector store collection...")
            bot.vector_store.reset()

        print("Building index from knowledge_base...")
        build_index(bot.vector_store)
        print("Index built successfully.\n")

    doc_count = bot.vector_store.count
    print(f"Documents in vector store: {doc_count}")
    if doc_count == 0:
        print("Warning: vector store is empty. Run with --index to build index from knowledge_base/")

    print("\nBot is ready. Type your questions (Ctrl+C or 'exit' to quit).\n")

    try:
        while True:
            user_input = input("You: ").strip()
            if not user_input:
                continue
            if user_input.lower() in ("exit", "quit", "q"):
                break

            answer = bot.ask(user_input)
            print(f"\nBot: {answer}\n")
    except (KeyboardInterrupt, EOFError):
        print("\nGoodbye!")


if __name__ == "__main__":
    main()
