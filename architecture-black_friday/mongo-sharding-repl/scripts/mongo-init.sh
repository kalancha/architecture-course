#!/bin/bash

docker compose exec -T mongos_router mongosh --port 27020 <<EOF
use somedb

// Заполняем данными
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF
