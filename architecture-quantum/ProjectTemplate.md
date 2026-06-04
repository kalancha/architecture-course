# Project: RAG-бот для QuantumForge Software

## Задание 1. Исследование моделей и инфраструктуры

### Сравнение LLM

| LLM | Качество ответов | Скорость | Стоимость | Простота развёртывания | Вывод |
|---|---:|---:|---:|---:|---|
| Локальные Hugging Face 7B | Среднее/хорошее | Средняя на GPU, низкая на CPU | Нет оплаты за токены, но нужен сервер | Сложно | Подходит, если нужен полный контроль и есть GPU |
| Локальные Hugging Face 13B+ | Хорошее | Требует мощный GPU | Высокая стоимость инфраструктуры | Сложно | Избыточно для MVP |
| OpenAI | Высокое | Высокая | Оплата за токены | Просто | Хороший production-вариант, но есть внешняя зависимость |
| YandexGPT | Хорошее для русского языка | Высокая | Оплата за токены | Просто | Лучший выбор для русскоязычного MVP |

Финальный выбор: YandexGPT. Он хорошо подходит для русского интерфейса, быстро подключается по API и не требует GPU на стороне проекта.

### Сравнение Embedding моделей

| Embedding model | Скорость индексации | Качество поиска | Стоимость | Вывод |
|---|---:|---:|---:|---|
| Локальные Sentence-Transformers | Высокая | Хорошее | Бесплатно локально | Оптимально для MVP |
| OpenAI Embeddings | Высокая | Высокое | Оплата за токены | Хорошо для production, но дороже и зависит от API |

Финальный выбор: `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`.

Причины:

- работает локально внутри Docker;
- поддерживает русский и английский язык;
- не требует оплаты за embedding-запросы;
- embedding size: 384;
- достаточно быстрый для базы знаний из десятков документов.

Model repo: https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2

### Сравнение Vector DBs

| Vector DB | Скорость поиска | Скорость индексации | Сложность внедрения | Поддержка | Удобство | Стоимость |
|---|---:|---:|---:|---:|---:|---:|
| ChromaDB | Хорошая | Хорошая | Низкая | Простая | Высокое | Бесплатно локально |
| FAISS | Очень высокая | Высокая | Средняя | Требует ручной логики | Среднее | Бесплатно локально |

Финальный выбор: ChromaDB.

Почему выбрана ChromaDB:

- хранит embeddings, документы и metadata в одном persistent-хранилище;
- проще внедряется в Python-проект;
- хорошо подходит для Docker Compose;
- не требует отдельного сервиса для MVP;

Почему не FAISS:

- FAISS быстрее на больших объёмах, но требует отдельного хранения metadata;
- для базы из 30+ документов скорость ChromaDB достаточна;
- ChromaDB удобнее для быстрого развертывания MVP RAG-пайплайна.

### Архитектурные опции

| Вариант | LLM | Embeddings | Vector DB | Interface | Когда подходит |
|---|---|---|---|---|---|
| Локальный MVP | YandexGPT | Sentence-Transformers | ChromaDB | CLI | Текущий проект |
| REST API | YandexGPT/OpenAI | Sentence-Transformers | ChromaDB | FastAPI | Для интеграции с внутренними системами |
| Cloud-first | OpenAI/YandexGPT | OpenAI Embeddings | Managed vector DB | API | Для production с SLA |
| Fully local | Hugging Face | Sentence-Transformers | FAISS/ChromaDB | CLI/API | Для закрытого контура с GPU |

### Рекомендуемая инфраструктура

Для выбранного MVP:

- CPU: 2-4 vCPU;
- RAM: 8-16 GB;
- GPU: не требуется;
- Disk: 5-20 GB под индекс, документы и логи.

Для полностью локального LLM:

- CPU: 8+ vCPU;
- RAM: 32+ GB;
- GPU: NVIDIA 12-24 GB VRAM.

Диаграмма системы:

![Архитектура RAG-пайплайна](diagrams/architecture.puml)

## Задание 2: База знаний

Взял полностью созданную ИИ Википедию Halupedia.

## Задание 3: Создание векторного индекса базы знаний

Модель:

- name: `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`;
- repo: https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2;
- embedding size: 384.

Chunking:

- chunk size: 220 слов;
- overlap: 40 слов;
- источник и позиция сохраняются в metadata.
- индексация занимает около минуты

Metadata:

- `source_path`;
- `title`;
- `chunk_id`;
- `chunk_index`.

Index:

- vector DB: ChromaDB;
- persistent directory: `chroma_db/`;
- last Docker indexing result: 174 chunks from 51 documents;
- rebuild command: `docker-compose run --rm indexer`;
- indexing code: `build_index.py`, `src/indexer.py`, `src/vectorstore.py`.

## Задание 4 и 5: Создание RAG бота, запуск и демонстрация работы бота

Примеры найденных ответов:
![Примеры найденных ответов:](assets/answers1.png)

Примеры ненайденных ответов:
![Примеры ненайденных ответов:](assets/answers2.png)

Пример поиска файла с уязвимыми данными без защиты:
![Пример поиска файла с уязвимыми данными без защиты:](assets/answers_without_safety.png)

Примеры поиска файла с уязвимыми данными с защитой:
![Примеры поиска файла с уязвимыми данными с защитой:](assets/answers_with_safety.png)
