# Architecture Black Friday

Набор локальных стендов для экспериментов с MongoDB:

- `mongo` - одиночный MongoDB + API
- `mongo-sharding` - шардирование + API
- `mongo-sharding-repl` - шардирование + replica set + API
- `sharding-repl-cache` - шардирование + replica set + Redis cache + API

## Требования

- Docker
- Docker Compose (plugin `docker compose`)

## Быстрый запуск

1. Перейдите в нужный подпроект:

```bash
cd mongo
# или: cd mongo-sharding
# или: cd mongo-sharding-repl
# или: cd sharding-repl-cache
```

2. Поднимите контейнеры:

```bash
docker compose up -d
```

3. Инициализируйте данные в MongoDB:

```bash
./scripts/mongo-init.sh
```

4. Откройте Swagger:

```text
http://localhost:8080/docs
```

## Дополнительные скрипты

Запускайте скрипты из директории выбранного подпроекта.

- `./scripts/mongo-init.sh` - заполнение тестовыми данными (есть во всех подпроектах).
- `./scripts/check-shards.sh` - проверка распределения данных по шардам (есть в `mongo-sharding`, `mongo-sharding-repl`, `sharding-repl-cache`).

## Остановка

В директории выбранного подпроекта:

```bash
docker compose down
```

