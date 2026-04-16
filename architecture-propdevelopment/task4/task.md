# Задание 4. Защита доступа к кластеру Kubernetes

## Ролевая модель Kubernetes

| Роль | Права роли | Группы пользователей |
| --- | --- | --- |
| `propdevelopment-cluster-admin` | Полный административный доступ ко всем ресурсам кластера. Используется только для платформенной команды, которая отвечает за эксплуатацию Kubernetes. | `propdev:k8s:cluster-admins` — руководители платформенной эксплуатации, старшие DevOps/SRE. |
| `propdevelopment-security-auditor` | Просмотр всех ресурсов кластера, включая `secrets`, `configmaps`, роли RBAC, события и логи Pod. Без права изменения ресурсов. | `propdev:k8s:security-auditors` — специалист ИБ и сотрудники, которым разрешён аудит секретов и чувствительных настроек. |
| `propdevelopment-cluster-viewer` | Только просмотр ресурсов кластера без доступа к `secrets`: namespaces, nodes, workloads, services, ingresses, events, logs. | `propdev:k8s:cluster-viewers` — бизнес-аналитики, владельцы продуктов, операционные менеджеры, которым нужен read-only доступ. |
| `propdevelopment-platform-engineer` | Настройка кластера и инфраструктурных объектов: namespaces, quotas, limitranges, networkpolicies, storageclasses, ingressclasses, workloads, services, configmaps. Без просмотра секретов и без управления RBAC. | `propdev:k8s:platform-engineers` — DevOps/SRE и инженеры эксплуатации, которые настраивают платформу. |
| `propdevelopment-domain-developer` | Управление прикладными ресурсами внутри namespace своего домена: deployments, statefulsets, daemonsets, jobs, cronjobs, pods, logs, services, ingresses, configmaps. Без доступа к `secrets`, RBAC и ресурсам других доменов. | `propdev:sales:developers`, `propdev:tenant:developers`, `propdev:finance:developers`, `propdev:data:developers`, `propdev:smarthome:developers` — функциональные команды доменов. |
| `propdevelopment-namespace-viewer` | Просмотр прикладных ресурсов внутри namespace своего домена без доступа к `secrets`. | `propdev:sales:operators`, `propdev:tenant:operators`, `propdev:finance:operators`, `propdev:data:analysts`, `propdev:smarthome:operators` — операционные команды и аналитики доменов. |

## Namespace-модель

| Namespace | Домен PropDevelopment | Назначение |
| --- | --- | --- |
| `pd-sales` | Группа сервисов для продаж | Витрина продаж, онлайн-тур, онлайн-сделка, CRM клиентов. |
| `pd-tenant-services` | Группа сервисов ЖКУ | Мобильное приложение собственников, tenant-core-app, CRM собственников. |
| `pd-finance` | Финансы | Сервисы бухгалтерского и финансового учёта. |
| `pd-data` | Data | DWH, BI, отчётность и аналитические сервисы. |
| `pd-smart-home` | Умный дом | Новые сервисы домофона, шлагбаума, API Gateway, biometry-adapter и smart-home-core-app. |

## Скрипты

| Скрипт | Назначение |
| --- | --- |
| `01-create-users.sh` | Создаёт тестовых пользователей Minikube через клиентские сертификаты и добавляет kubeconfig-контексты. |
| `02-create-roles.sh` | Создаёт namespaces, ClusterRole и Role для выбранной ролевой модели. |
| `03-bind-users.sh` | Связывает группы пользователей с ролями через ClusterRoleBinding и RoleBinding. |

## Проверка

После запуска скриптов можно проверить права командами:

```bash
kubectl auth can-i get secrets --as=pd-security-auditor --as-group=propdev:k8s:security-auditors -A
kubectl auth can-i get secrets --as=pd-cluster-viewer --as-group=propdev:k8s:cluster-viewers -A
kubectl auth can-i create deployments --as=pd-sales-dev --as-group=propdev:sales:developers -n pd-sales
kubectl auth can-i create deployments --as=pd-sales-dev --as-group=propdev:sales:developers -n pd-finance
kubectl auth can-i create networkpolicies --as=pd-platform-engineer --as-group=propdev:k8s:platform-engineers -A
```

