#!/bin/bash

echo "=== Распределение данных по шардам ==="
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
use somedb
db.helloDoc.getShardDistribution()
EOF
