# mongo-sharding

## Как запустить (из папки mongo-sharding)

Запускаем mongodb и приложение

```shell
docker compose up -d
```

Инициализируем/заполняем и проверяем кластер mongodb

```shell
./sharding-init.sh
```

В конце скрипта выполняются проверки в соответствии с заданием
