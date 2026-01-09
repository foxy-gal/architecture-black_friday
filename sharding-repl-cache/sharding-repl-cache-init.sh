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

docker compose exec -T shard1_1 mongosh --port 27001 --quiet <<EOF 1>/dev/null
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1_1:27001" },
        { _id : 1, host : "shard1_2:27002" },
        { _id : 2, host : "shard1_3:27003" }
      ]
    }
);
EOF

###
# Инициализируем шард 2
###

echo "Инициализируем шард 2..."

docker compose exec -T shard2_1 mongosh --port 27011 --quiet <<EOF 1>/dev/null
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2_1:27011" },
        { _id : 1, host : "shard2_2:27012" },
        { _id : 2, host : "shard2_3:27013" }
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
sh.addShard("shard1/shard1_1:27001");
sh.addShard("shard2/shard2_1:27011");
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

###
# Проверка шарда 1
###

echo "Проверяем количество документов на шарде 1 реплике 1..."

docker compose exec -T shard1_1 mongosh --port 27001 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем количество документов на шарде 1 реплике 2..."

docker compose exec -T shard1_2 mongosh --port 27002 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем количество документов на шарде 1 реплике 3..."

docker compose exec -T shard1_3 mongosh --port 27003 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

###
# Проверка шарда 2
###

echo "Проверяем количество документов на шарде 2 реплике 1..."

docker compose exec -T shard2_1 mongosh --port 27011 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем количество документов на шарде 2 реплике 2..."

docker compose exec -T shard2_2 mongosh --port 27012 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем количество документов на шарде 2 реплике 3..."

docker compose exec -T shard2_3 mongosh --port 27013 --quiet <<EOF
use somedb
db.helloDoc.countDocuments()
EOF
echo

echo "Проверяем через микросервис..."

curl http://localhost:8080/helloDoc/count
echo

echo "Время выполнения 1 запроса..."
curl -s -o /dev/null \
  -w "time_total=%{time_total}s\n" \
  http://localhost:8080/helloDoc/users

echo "Время выполнения 2 запроса..."
curl -s -o /dev/null \
  -w "time_total=%{time_total}s\n" \
  http://localhost:8080/helloDoc/users

echo "Время выполнения 3 запроса..."
curl -s -o /dev/null \
  -w "time_total=%{time_total}s\n" \
  http://localhost:8080/helloDoc/users