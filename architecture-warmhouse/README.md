# Project_template

# Задание 1. Анализ и планирование

### 1. Описание функциональности монолитного приложения

**Управление отоплением:**

- Пользователи могут удалённо включать/выключать отопление в своих домах.
- Система поддерживает функционал управления датчиками в домах клиентов.

**Мониторинг температуры:**

- Пользователи могут смотреть на показания датчиков, установленных в их доме через веб-интерфейс.
- Система получает данные о температуре с датчиков, установленных в домах. Пользователи могут просматривать текущую температуру в своих домах через веб-интерфейс.

**Подключение устройств:**
- Пользователь не может самостоятельно подключить новый датчик
- Система позволяет подключить новый датчик в систему путем выезда специалиста по подключению системы отопления в доме

### 2. Анализ архитектуры монолитного приложения

- Язык программирования: Go
- База данных: PostgreSQL
- Архитектура: Монолитная, все компоненты системы (обработка запросов, бизнес-логика, работа с данными) находятся в рамках одного приложения.
- Взаимодействие: Синхронное, запросы обрабатываются последовательно.
- Масштабируемость: Ограничена, так как монолит сложно масштабировать по частям.
- Развертывание: Требует остановки всего приложения.

### 3. Определение доменов и границы контекстов

#### Домен управления устройствами
**Контекст: состояние пользовательских датчиков**
Знает, какие устройства есть в доме и каково их состояние, но не знает, как физически с ними взаимодействовать и какие сценарии на них завязаны

**Контекст: управление оборудования**
Работает исключительно с «железом», не знает о бизнес-логике, пользователях или правилах автоматизации

#### Домен автоматизации
**Контекст: Сценарии**
Работает сценариями в доме, на основе событий вычисляет	 какие операции надо провести с датчиками, информировать пользователя и тд

#### Домен управления пользователями и топологией
**Контекст: Пользователи и дома**
Управляет регистрацией, аутентификацией, профилями пользователей, а также структурой домов, комнат и правами совместного доступа (home_members). Не знает о конкретных устройствах и сценариях — только предоставляет топологию для других доменов.

#### Домен уведомлений
**Контекст: Уведомления**
Граница: не принимает решений о том, когда уведомлять — только доставляет сообщения по запросу от других доменов


### 4. Проблемы монолитного решения

- Невозможно инфраструктурно масштабировать отдельные высоконагруженные части сервиса
- Единая точка отказа. Если где-то упал какой-то процесс, приложение падает целиком
- Высокая связность кода. Очень легко задеть что-то в одном месте, что сломает другой конец системы
- Ограничение текхнологического стека. Вся логика должна быть написана на одном стеке

### 5. Визуализация контекста системы — диаграмма С4

## C4 Level 1: Context
![Context](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/Context.puml)

# Задание 2. Проектирование микросервисной архитектуры

**Диаграмма контейнеров (Containers)**

![Container](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/Container.puml)

**Message Broker — потоки данных**

![Broker](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/MessageBrokerComponent.puml)

**Диаграмма компонентов (Components)**

Core Service:

![CoreService](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/CoreServiceComponent.puml)

Automation Service:

![AutomationService](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/AutomationServiceComponent.puml)

Connection Service:

![ConnectService](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/ConnectServiceComponent.puml)

Notification Service:

![NotifierService](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/NotifierComponent.puml)

Web UI:

![WebUI](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/WebComponent.puml)

**Диаграмма кода (Code)**

Automation Service:

![AutomationCode](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/AutomationServiceComponentCode.puml)

Connection Service:

![ConnectionCode](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/ConnectionServiceComponentCode.puml)

# Задание 3. Разработка ER-диаграммы

![ER](https://www.plantuml.com/plantuml/proxy?src=https://raw.githubusercontent.com/kalancha/architecture-course/warmhouse/architecture-warmhouse/apps/diagrams/ER.puml)

# Задание 4. Создание и документирование API

### 1. Тип API

В системе используются **два типа API**, каждый из которых решает свою задачу:

| Тип | Протокол | Формат спецификации | Где применяется |
|-----|----------|---------------------|-----------------|
| **Синхронный (REST)** | HTTP/JSON | OpenAPI 3.0 | Web UI ↔ Core Service |
| **Асинхронный (Event-driven)** | MQTT | AsyncAPI 2.6 | Взаимодействие между микросервисами через Message Broker |

**REST API (OpenAPI 3.0)** — используется для взаимодействия Web UI с бэкендом через Core Service, который выступает единой точкой входа (API Gateway). REST выбран, потому что:
- Клиент (Web UI) работает в модели запрос-ответ: пользователь совершает действие и ожидает результат.
- Все операции идемпотентны и хорошо ложатся на CRUD-семантику HTTP-методов.
- JWT-аутентификация естественно реализуется через заголовок `Authorization: Bearer`.

**MQTT (AsyncAPI 2.6)** — используется для асинхронного взаимодействия между микросервисами через Message Broker. MQTT выбран, потому что:
- IoT-устройства генерируют события непредсказуемо — push-модель эффективнее polling.
- Требуется fan-out: одно событие от датчика (топик `home/events/{deviceId}/state`) должно попасть одновременно в Core Service (сохранение состояния) и Automation Service (проверка правил).
- Команды устройствам (`home/commands/{deviceId}/set`) отправляются fire-and-forget — ответ не требуется синхронно.
- Отправка уведомлений (`sys/notify/dispatch`) - фоновая задачи, не блокирующая пользователя.

### 2. Документация API

#### REST API — Core Service (OpenAPI 3.0)

Спецификация: [`apps/api-specs/core-service-openapi.yaml`](architecture-warmhouse/apps/api-specs/core-service-openapi.yaml)

Core Service является единой точкой входа для Web UI и объединяет следующие группы эндпоинтов:

| Группа | Эндпоинты | Описание |
|--------|-----------|----------|
| **Auth** | `POST /api/v1/auth/register`, `POST /api/v1/auth/login` | Регистрация и аутентификация (JWT) |
| **Users** | `GET/PUT /api/v1/users/me` | Профиль пользователя |
| **Homes** | `GET/POST /api/v1/homes`, `GET/PUT/DELETE /api/v1/homes/{homeId}` | Управление домами |
| **Home Members** | `GET/POST /api/v1/homes/{homeId}/members`, `DELETE .../members/{userId}` | Совместный доступ к дому |
| **Rooms** | `GET/POST /api/v1/homes/{homeId}/rooms`, `GET/PUT/DELETE .../rooms/{roomId}` | Комнаты внутри дома |
| **Devices** | `GET/POST /api/v1/homes/{homeId}/devices`, `GET/PUT/DELETE /api/v1/devices/{deviceId}` | Привязка и управление устройствами |
| **Device Commands** | `POST /api/v1/devices/{deviceId}/command` | Отправка команды устройству (публикация в MQTT) |
| **Device State** | `GET /api/v1/devices/{deviceId}/state`, `GET .../history` | Текущее состояние и история |
| **Automation Rules** | `GET/POST /api/v1/homes/{homeId}/rules`, `GET/PUT/DELETE /api/v1/rules/{ruleId}`, `PATCH .../toggle`, `GET .../logs` | Сценарии автоматизации |
| **Notifications** | `GET /api/v1/notifications`, `GET/POST/PUT/DELETE .../notification-channels` | Уведомления и каналы доставки |
| **Telegram** | `POST /api/v1/users/me/telegram/link-token`, `GET/DELETE /api/v1/users/me/telegram` | Привязка Telegram-аккаунта |

#### Асинхронный API — MQTT Event Bus (AsyncAPI 2.6)

Спецификация: [`apps/api-specs/asyncapi.yaml`](architecture-warmhouse/apps/api-specs/asyncapi.yaml)

Асинхронное взаимодействие между микросервисами через MQTT-брокер:

| Топик | Publisher | Subscriber | Назначение |
|-------|-----------|------------|------------|
| `home/events/{deviceId}/state` | Connect Service | Core Service, Automation Service | События от датчиков (температура изменилась, устройство online/offline) |
| `home/commands/{deviceId}/set` | Core Service, Automation Service | Connect Service | Команды управления устройствами (включить, задать температуру) |
| `sys/notify/dispatch` | Automation Service, Core Service | Notifier Service | Задачи на отправку уведомлений пользователям |
