# RAG-бот для QuantumForge Software

Учебный RAG-проект для поиска по корпоративной базе знаний QuantumForge Software. Бот ищет релевантные фрагменты в локальной базе, отвечает только на основе найденного контекста и отказывается отвечать, если фактов недостаточно.

## Стек

- Python 3.11
- ChromaDB
- Sentence-Transformers `paraphrase-multilingual-MiniLM-L12-v2`
- YandexGPT API
- Docker Compose

## Структура

- `ProjectTemplate.md` — отчёт по заданию.
- `knowledge_base/` — уникальная база знаний, 51 документ.
- `build_index.py` — пересборка индекса.
- `rag_bot.py` — запуск консольного бота.
- `src/` — код RAG-пайплайна.
- `chroma_db/` — persistent ChromaDB index.
- `diagrams/architecture.puml` — PlantUML-схема архитектуры.

## Запуск через Docker

```bash
cp .env.example .env
```

Заполните в `.env`:

```bash
YANDEX_API_KEY=...
YANDEX_FOLDER_ID=...
```

Соберите индекс:

```bash
docker-compose build
docker-compose run --rm indexer
```

Запустите бота:

```bash
docker-compose run --rm rag-bot
```

## Полезные Docker-команды

```bash
docker-compose build
docker-compose run --rm indexer
docker-compose run --rm rag-bot
```
