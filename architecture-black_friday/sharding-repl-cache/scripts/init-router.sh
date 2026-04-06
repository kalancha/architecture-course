#!/bin/bash

echo 'Waiting for shards to initialize...'
sleep 15

echo 'Adding shards to router...'
mongosh --host mongos_router:27020 --eval 'sh.addShard("shard1/shard1-1:27018,shard1-2:27118,shard1-3:27218")' || true
mongosh --host mongos_router:27020 --eval 'sh.addShard("shard2/shard2-1:27019,shard2-2:27119,shard2-3:27219")' || true

echo 'Enabling sharding for database...'
mongosh --host mongos_router:27020 --eval 'sh.enableSharding("somedb")' || true

echo 'Enabling sharding for collection...'
mongosh --host mongos_router:27020 --eval 'sh.shardCollection("somedb.helloDoc", { "name" : "hashed" })' || true

echo 'Setup completed successfully!'
