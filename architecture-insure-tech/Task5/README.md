# Task5. GraphQL API для client-info

## Анализ REST API

В исходном Swagger есть три ресурса:

- `GET /clients/{id}` - базовая карточка клиента;
- `GET /clients/{id}/documents` - документы клиента;
- `GET /clients/{id}/relatives` - родственники клиента.

Проблема REST-подхода в этом сценарии: если потребителю нужны клиент, документы и родственники, ему приходится делать несколько запросов. Если сделать один REST endpoint со всеми 500 атрибутами клиента, появится другая проблема: overfetching, то есть передача лишних данных.

## Как GraphQL решает задачу

GraphQL схема в `schema.graphql` оставляет те же сущности:

- `Client`;
- `Document`;
- `Relative`.

Но потребитель может сам выбрать нужные поля:

```graphql
query GetClientForPolicy($id: ID!) {
  client(id: $id) {
    id
    name
    documents {
      type
      number
      expiryDate
    }
  }
}
```

Если родственники в сценарии не нужны, они не запрашиваются и не передаются.

## Эквивалентность REST операциям

Получить клиента:

```graphql
query {
  client(id: "client-1") {
    id
    name
    age
  }
}
```

Получить документы:

```graphql
query {
  documents(clientId: "client-1") {
    id
    type
    number
    issueDate
    expiryDate
  }
}
```

Получить родственников:

```graphql
query {
  relatives(clientId: "client-1") {
    id
    relationType
    name
    age
  }
}
```

Получить всё одним запросом, но только с нужными полями:

```graphql
query {
  client(id: "client-1") {
    id
    name
    documents {
      type
      number
    }
    relatives {
      relationType
      name
    }
  }
}
```
