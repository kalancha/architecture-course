# Задание 5. Управление трафиком внутри кластера Kubernetes

## Что разворачиваем

Все Pod и Service создаются в одном namespace `task5`.

| Service/Pod | Метка | Назначение |
| --- | --- | --- |
| `front-end-app` | `role=front-end` | Пользовательский UI. Может общаться только с `back-end-api-app`. |
| `back-end-api-app` | `role=back-end-api` | Пользовательский API. Может общаться только с `front-end-app`. |
| `admin-front-end-app` | `role=admin-front-end` | Административный UI. Может общаться только с `admin-back-end-api-app`. |
| `admin-back-end-api-app` | `role=admin-back-end-api` | Административный API. Может общаться только с `admin-front-end-app`. |

## Команды для создания сервисов

Для проверки блокировки трафика Minikube должен быть запущен с CNI, который поддерживает NetworkPolicy, например:

```bash
minikube start --cni=calico
```

Если использовать стандартный `bridge`/`auto` CNI без поддержки NetworkPolicy, ресурсы `NetworkPolicy` создадутся, но трафик фактически блокироваться не будет.

```bash
kubectl apply -f non-admin-api-allow.yaml

kubectl run front-end-app \
  --namespace task5 \
  --image=nginx \
  --labels role=front-end \
  --expose \
  --port 80

kubectl run back-end-api-app \
  --namespace task5 \
  --image=nginx \
  --labels role=back-end-api \
  --expose \
  --port 80

kubectl run admin-front-end-app \
  --namespace task5 \
  --image=nginx \
  --labels role=admin-front-end \
  --expose \
  --port 80

kubectl run admin-back-end-api-app \
  --namespace task5 \
  --image=nginx \
  --labels role=admin-back-end-api \
  --expose \
  --port 80
```

## Как проверить

Разрешенный трафик:

```bash
kubectl run test-front-end-$RANDOM \
  --namespace task5 \
  --rm -i -t \
  --image=alpine \
  --labels role=front-end \
  -- sh

wget -qO- --timeout=2 http://back-end-api-app
```

```bash
kubectl run test-admin-front-end-$RANDOM \
  --namespace task5 \
  --rm -i -t \
  --image=alpine \
  --labels role=admin-front-end \
  -- sh

wget -qO- --timeout=2 http://admin-back-end-api-app
```

Запрещенный трафик:

```bash
kubectl run test-front-end-$RANDOM \
  --namespace task5 \
  --rm -i -t \
  --image=alpine \
  --labels role=front-end \
  -- sh

wget -qO- --timeout=2 http://admin-back-end-api-app
```

```bash
kubectl run test-admin-front-end-$RANDOM \
  --namespace task5 \
  --rm -i -t \
  --image=alpine \
  --labels role=admin-front-end \
  -- sh

wget -qO- --timeout=2 http://back-end-api-app
```

Ожидаемый результат:

- `front-end` получает ответ от `back-end-api`;
- `admin-front-end` получает ответ от `admin-back-end-api`;
- `front-end` не получает ответ от `admin-back-end-api`;
- `admin-front-end` не получает ответ от `back-end-api`.
