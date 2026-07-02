# BionicPRO SSO and Reports

Локальный стенд для практических заданий по SSO и сервису отчётов BionicPRO.

## Что входит в стенд

- `frontend` - React-приложение, доступно на `http://localhost:3000`.
- `keycloak` - SSO провайдер, realm `reports-realm`, доступен на `http://localhost:8080`.
- `reports-api` - Node.js Express API отчётов, доступен на `http://localhost:8000`.
- `crm_db` - PostgreSQL с seed-данными о пользователях, протезах и владении протезами.
- `clickhouse` - OLAP-хранилище с сырой телеметрией, витриной `report_mart` и таблицей `etl_runs`.
- `airflow-webserver` / `airflow-scheduler` - ETL для построения отчётной витрины, UI на `http://localhost:8081`.

Диаграммы:

- `model_1.drawio` - архитектура задания 1, SSO.
- `model_2.drawio` - архитектура задания 2, сервис отчётов.

## Запуск проекта

Нужны Docker и Docker Compose.

```bash
docker-compose up -d --build
```

Проверить, что сервисы поднялись:

```bash
docker-compose ps
```

Ожидаемые публичные порты:

- Frontend: `http://localhost:3000`
- Keycloak: `http://localhost:8080`
- Reports API: `http://localhost:8000`
- Airflow: `http://localhost:8081`
- ClickHouse HTTP: `http://localhost:8123`

## Тестовые пользователи

Пользователи с отчётами:

```text
prothetic1 / prothetic123
prothetic2 / prothetic123
prothetic3 / prothetic123
```

Тестовые пользователи `user1` / `user2` нужны для SSO-проверок, но в CRM к ним не привязаны протезы, поэтому отчётов у них нет.

Airflow:

```text
admin / admin
```

Keycloak admin:

```text
admin / admin
```

## Проверка задания 1: SSO

1. Открыть `http://localhost:3000`.
2. Нажать `Login`.
3. Войти пользователем `prothetic1 / prothetic123`.
4. После входа пользователь должен вернуться во frontend.

В Keycloak client `reports-frontend` настроен Authorization Code Flow с PKCE S256.

## Проверка задания 2: отчёты

Сначала нужно построить витрину отчётов через Airflow:

```bash
docker-compose exec airflow-scheduler airflow dags test bionicpro_reports_etl 2026-06-23
```

Проверить, что витрина наполнилась:

```bash
curl 'http://localhost:8123/?database=bionicpro&user=default&password=clickhouse_password' \
  --data-binary 'SELECT count() FROM report_mart'
```

Ожидаемый результат:

```text
9
```

Проверить последний успешный ETL-run:

```bash
curl 'http://localhost:8123/?database=bionicpro&user=default&password=clickhouse_password' \
  --data-binary "SELECT period_start, period_end, status, records_loaded FROM etl_runs ORDER BY processed_at DESC LIMIT 1 FORMAT JSONEachRow"
```

Ожидаемый период:

```text
2026-06-20 - 2026-06-22
```

Ожидаемый статус:

```text
success
```

## Проверка Reports API

Healthcheck:

```bash
curl http://localhost:8000/health
```

Ожидаемый ответ:

```json
{"status":"ok"}
```

Без JWT отчёт должен быть закрыт:

```bash
curl -i http://localhost:8000/reports
```

Ожидаемый результат: `401 Unauthorized`.

Через UI:

1. Открыть `http://localhost:3000`.
2. Войти как `prothetic1 / prothetic123`.
3. Нажать `Get Report`.
4. На странице должен появиться отчёт за период `2026-06-20 - 2026-06-22`.

Для `prothetic1` ожидаются только его протезы:

- `bp-arm-1001`
- `bp-hand-1002`

API берёт пользователя из JWT, а не из query/body, поэтому клиент не может запросить отчёт другого пользователя.

## Сброс стенда

Остановить контейнеры:

```bash
docker-compose down
```

Полностью пересоздать данные, включая volumes:

```bash
docker-compose down -v
docker-compose up -d --build
```

После полного сброса нужно снова прогнать Airflow DAG для построения `report_mart`.
