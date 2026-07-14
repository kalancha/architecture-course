# Задание 1. Data Flow Diagrams

## Процесс 1. Запись пациента и договор, As-Is

```mermaid
flowchart LR
    patient[Пациент] -->|Ф. И. О., дата рождения, телефон, email, расширенная анкета| reception[Ресепшен]
    reception -->|Ручной ввод записи| excel[(Excel: журнал приёма)]
    reception -->|Скан договора, анкеты, согласия| shared[(Общий диск: JPG/PDF)]
    reception -->|Напоминание вручную| outlook[Outlook / Exchange]
    excel --> doctor[Медицинский специалист]
    shared --> doctor
    outlook --> patient

    classDef sensitive fill:#ffd6d6,stroke:#b42318,color:#111;
    classDef risk fill:#fff1c2,stroke:#b7791f,color:#111;
    class patient,reception,excel,shared,doctor sensitive;
    class outlook risk;
```

Проблемы:

- PII и медицинские сведения попадают в Excel и сканы без классификации.
- Общий диск не разделяет доступ по роли и цели обработки.
- Нет аудита чтения, скачивания и изменения файлов.
- Расширенная анкета может собирать больше данных, чем нужно для записи.

## Процесс 1. Запись пациента и договор, To-Be

```mermaid
flowchart LR
    patient[Пациент] -->|TLS, минимальная форма записи| portal[Портал клиента]
    reception[Ресепшен] -->|TLS, рабочее место| staffPortal[Портал ресепшена]
    portal --> api[API Gateway]
    staffPortal --> api
    api --> iam[IAM: RBAC/ABAC]
    iam --> appointment[Сервис записи]
    iam --> crm[CRM пациента]
    iam --> docs[Сервис договоров]
    appointment --> apptDb[(БД записей, encrypted at rest)]
    crm --> crmDb[(БД пациентов, PII tags)]
    docs --> objectStore[(Шифрованное хранилище документов)]
    appointment --> notify[Сервис уведомлений]
    notify --> patient
    appointment --> audit[(Audit log)]
    crm --> audit
    docs --> audit
    crm --> catalog[Каталог данных и теги]
    docs --> catalog

    classDef control fill:#d9eafd,stroke:#2563eb,color:#111;
    classDef storage fill:#e7f6df,stroke:#2f855a,color:#111;
    classDef sensitive fill:#ffd6d6,stroke:#b42318,color:#111;
    class api,iam,audit,catalog control;
    class apptDb,crmDb,objectStore storage;
    class patient,crm,docs sensitive;
```

Добавленные меры:

- Privacy by default: форма записи собирает только минимальный набор данных.
- Теги: `PII`, `CONTRACT`, `RETENTION_LIMITED`.
- Доступ: ресепшен видит данные для записи и договора, но не полную медицинскую карту.
- Аудит: чтение и изменение чувствительных данных пишутся в журнал.
- Data Lineage: событие создания записи связывает пациента, источник и дальнейшие действия.

## Процесс 2. Медицинская карта и анализы, As-Is

```mermaid
flowchart LR
    patient[Пациент] -->|Жалобы, анамнез, хронические заболевания| doctor[Медицинский специалист]
    doctor -->|Ручное заполнение| medFiles[(Excel / JPG / PDF: медкарта)]
    doctor -->|Файлы анализов| shared[(Общий диск)]
    lab[Лаборатория анализов / документы] -->|Ручная передача результата| reception[Ресепшен]
    reception -->|Скан или файл| shared
    shared --> doctor
    shared --> reception

    classDef sensitive fill:#ffd6d6,stroke:#b42318,color:#111;
    classDef risk fill:#fff1c2,stroke:#b7791f,color:#111;
    class patient,doctor,medFiles,shared,lab sensitive;
    class reception risk;
```

Проблемы:

- Медицинские данные лежат в файловом виде без тегов и жизненного цикла.
- Нет гарантии, что врач видит только пациентов, с которыми работает.
- Нет контролируемой интеграции с лабораторией.
- Результаты анализов и заключения могут копироваться в неуправляемые файлы.

## Процесс 2. Медицинская карта и анализы, To-Be

```mermaid
flowchart LR
    patient[Пациент] --> portal[Портал клиента]
    doctor[Медицинский специалист] --> medUi[Медицинское рабочее место]
    lab[API лаборатории] -->|mTLS, минимальный контракт| api[API Gateway]
    portal --> api
    medUi --> api
    api --> iam[IAM: роль + назначение + patient_id]
    iam --> ehr[Сервис медицинской карты]
    iam --> labSvc[Сервис лабораторных результатов]
    ehr --> ehrDb[(БД медкарты, tag MEDICAL)]
    labSvc --> labDb[(БД результатов анализов, tag MEDICAL)]
    ehr --> audit[(Audit log)]
    labSvc --> audit
    ehr --> catalog[Каталог данных / lineage]
    labSvc --> catalog
    ehr --> dataLake[(Обезличенный аналитический слой)]
    labSvc --> dataLake

    classDef control fill:#d9eafd,stroke:#2563eb,color:#111;
    classDef storage fill:#e7f6df,stroke:#2f855a,color:#111;
    classDef sensitive fill:#ffd6d6,stroke:#b42318,color:#111;
    class api,iam,audit,catalog control;
    class ehrDb,labDb,dataLake storage;
    class patient,doctor,lab,ehr,labSvc sensitive;
```

Добавленные меры:

- API лаборатории не выдаёт и не принимает лишние категории данных.
- Доступ врача проверяется не только по роли, но и по связи с назначением пациента.
- В аналитику передаются обезличенные или агрегированные данные.
- По каждому результату анализа фиксируется источник, время получения и дальнейшие потребители.

## Процесс 3. Оплата и бухгалтерский учёт, As-Is

```mermaid
flowchart LR
    patient[Пациент] -->|Оплата услуги| cashier[Кассир]
    cashier -->|Кассовая операция| kkm[ККМ]
    kkm -->|TCP/IP + OLE| onec[(1С:Бухгалтерия, файловый режим)]
    cashier -->|Дублирующий ручной учёт| excel[(Excel)]
    onec --> accounting[Бухгалтерия]
    excel --> accounting
    accounting --> tax[Налоговая отчётность]

    classDef sensitive fill:#ffd6d6,stroke:#b42318,color:#111;
    classDef risk fill:#fff1c2,stroke:#b7791f,color:#111;
    class patient,cashier,onec,excel,accounting sensitive;
    class kkm risk;
```

Проблемы:

- Двойной ручной учёт создаёт риск рассинхронизации.
- Платёжные данные связаны с пациентом, но не отделены от медицинских данных как отдельный домен.
- 1С работает в файловом режиме на локальном сервере.
- Нет единого аудита доступа к платежам и договорным данным.

## Процесс 3. Оплата и бухгалтерский учёт, To-Be

```mermaid
flowchart LR
    patient[Пациент] -->|Оплата| paymentGateway[Платёжный шлюз]
    cashier[Кассир] --> cashierUi[Рабочее место кассира]
    cashierUi --> api[API Gateway]
    paymentGateway --> api
    api --> iam[IAM: роли кассира и бухгалтерии]
    iam --> payment[Сервис платежей]
    payment --> paymentDb[(БД платежей, tag PAYMENT)]
    payment --> onec[Интеграция с 1С]
    onec --> onecDb[(1С:Бухгалтерия)]
    payment --> audit[(Audit log)]
    payment --> catalog[Каталог данных / lineage]
    payment --> reports[(Финансовые витрины без MEDICAL)]

    classDef control fill:#d9eafd,stroke:#2563eb,color:#111;
    classDef storage fill:#e7f6df,stroke:#2f855a,color:#111;
    classDef sensitive fill:#ffd6d6,stroke:#b42318,color:#111;
    class api,iam,audit,catalog control;
    class paymentDb,onecDb,reports storage;
    class patient,paymentGateway,cashier,payment,onec sensitive;
```

Добавленные меры:

- Платёжный домен отделён от медицинского домена.
- Кассир видит минимальные идентификаторы пациента, необходимые для оплаты.
- Бухгалтерия работает с платежами и налоговыми данными без доступа к медицинской карте.
- Отчёты строятся из контролируемых витрин, а не из ручных Excel-дублей.

## Процесс 4. BI, ML, AI и LLM, To-Be

```mermaid
flowchart LR
    crmDb[(CRM / PII)] --> etl[Контролируемый ETL / NiFi]
    ehrDb[(Медицинская карта / MEDICAL)] --> etl
    paymentDb[(Платежи / PAYMENT)] --> etl
    etl --> minimization[Минимизация и фильтрация]
    minimization --> masking[Маскирование / обезличивание]
    masking --> lake[(Озеро данных: ANALYTICS_SAFE)]
    lake --> bi[BI-отчёты]
    lake --> ml[ML / AI / LLM-песочница]
    etl --> lineage[Data Lineage]
    lake --> catalog[Каталог и теги]
    bi --> audit[(Аудит доступа)]
    ml --> audit

    classDef control fill:#d9eafd,stroke:#2563eb,color:#111;
    classDef storage fill:#e7f6df,stroke:#2f855a,color:#111;
    classDef sensitive fill:#ffd6d6,stroke:#b42318,color:#111;
    class etl,minimization,masking,lineage,catalog,audit control;
    class lake storage;
    class crmDb,ehrDb,paymentDb sensitive;
```

Добавленные меры:

- Сырые PII и медицинские данные не передаются напрямую в BI/ML/AI.
- Перед аналитическим использованием применяются минимизация, маскирование и обезличивание.
- Для каждого набора фиксируются источник, трансформация и потребитель.
- Аналитик получает только наборы с тегом `ANALYTICS_SAFE`.
