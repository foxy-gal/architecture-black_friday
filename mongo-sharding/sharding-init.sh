#!/bin/bash

###
# Инициализируем конфиг-сервер
###

echo "Инициализируем конфиг-сервер..."

docker compose exec -T config_srv mongosh --port 27017 --quiet <<EOF 1>/dev/null
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "config_srv:27017" }
    ]
  }
);
EOF

###
# Инициализируем шард 1
###

echo "Инициализируем шард 1..."

docker compose exec -T shard1 mongosh --port 27001 --quiet <<EOF 1>/dev/null
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27001" }
      ]
    }
);
EOF

###
# Инициализируем шард 2
###

echo "Инициализируем шард 2..."

docker compose exec -T shard2 mongosh --port 27002 --quiet <<EOF 1>/dev/null
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2:27002" }
      ]
    }
);
EOF

###
# Инициализируем роутер
###
echo "Ждем 20 секунд для инициализации..."
sleep 20
echo "Инициализируем роутер..."

docker compose exec -T mongos_router mongosh --port 27018 --quiet <<EOF 1>/dev/null
sh.addShard("shard1/shard1:27001");
sh.addShard("shard2/shard2:27002");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });
EOF


###
# Тестовые данные
###

echo "Добавляем тестовые данные..."

docker compose exec -T mongos_router mongosh --port 27018 --quiet <<EOF 1>/dev/null
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF

###
# Проверка
###

echo "Проверяем количество документов..."

docker compose exec -T mongos_router mongosh --port 27018 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем количество документов на шарде 1..."

docker compose exec -T shard1 mongosh --port 27001 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем количество документов на шарде 2..."

docker compose exec -T shard2 mongosh --port 27002 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем через микросервис..."

curl http://localhost:8080/helloDoc/count