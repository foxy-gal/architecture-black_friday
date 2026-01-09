# sharding-repl-cache

## Как запустить (из папки sharding-repl-cache)

Запускаем mongodb и приложение

```shell
docker compose up -d
```

Инициализируем/заполняем и проверяем кластер mongodb

```shell
./sharding-repl-cache-init.sh
```

В конце скрипта выполняются проверки в соответствии с заданием

