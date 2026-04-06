#!/bin/bash

echo 'Initializing config server...'
mongosh --host configSrv:27017 --eval 'rs.initiate({_id: "config_server", configsvr: true, members: [{_id: 0, host: "configSrv:27017"}]})' || true

echo 'Initializing shard1...'
mongosh --host shard1:27018 --eval 'rs.initiate({_id: "shard1", members: [{_id: 0, host: "shard1:27018"}]})' || true

echo 'Initializing shard2...'
mongosh --host shard2:27019 --eval 'rs.initiate({_id: "shard2", members: [{_id: 0, host: "shard2:27019"}]})' || true

echo 'Replica sets initialized!'