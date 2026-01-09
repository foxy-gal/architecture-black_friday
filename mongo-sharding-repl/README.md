# mongo-sharding-repl

## Как запустить (из папки mongo-sharding-repl)

Запускаем mongodb и приложение

```shell
docker compose up -d
```

Инициализируем/заполняем и проверяем кластер mongodb

```shell
./sharding-repl-init.sh
```

В конце скрипта выполняются проверки в соответствии с заданием
