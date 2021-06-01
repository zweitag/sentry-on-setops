setops login
setops registry get-login-command
setops create stage sentry-production
setops --stage sentry-production commit


# -- Create Volumes
# ---------------------------
sos service create clickhouse --type volume
sos service create clickhouse-log --type volume
sos service create sentry-data --type volume
sos service create kafka --type volume
sos service create kafka-log --type volume
sos service create postgres --type volume
sos service create redis --type volume
sos service create symbolicator --type volume
sos service create zookeeper --type volume
sos service create zookeeper-log --type volume
sos service create sentry-secrets --type volume
sos commit

# -- Zookeeper
# ---------------------------
setops --stage sentry-production app create zookeeper
setops --stage sentry-production app env set zookeeper ZOOKEEPER_CLIENT_PORT="2181"
setops --stage sentry-production app env set zookeeper CONFLUENT_SUPPORT_METRICS_ENABLE="false"
setops --stage sentry-production app env set zookeeper ZOOKEEPER_LOG4J_ROOT_LOGLEVEL="WARN"
setops --stage sentry-production app env set zookeeper ZOOKEEPER_TOOLS_LOG4J_LOGLEVEL="WARN"
sos app env set zookeeper KAFKA_OPTS="-Dzookeeper.4lw.commands.whitelist=ruok"
sos app port set zookeeper 2181
setops --stage sentry-production commit

sos service link create zookeeper zookeeper --path /var/lib/zookeeper/data
sos service link create zookeeper-log zookeeper --path /var/lib/zookeeper/log
sos service link create sentry-secrets zookeeper --path /etc/zookeeper/secrets
sos commit

cd zookeeper
docker build -t zweitag.setops.net/sentry/production:zookeeper_1 .
docker push zweitag.setops.net/sentry/production:zookeeper_1
sos app scale set zookeeper 0
setops --stage sentry-production app release create zookeeper --digest
setops --stage sentry-production app release set zookeeper 3
setops --stage sentry-production commit

sos run zookeeper -- /setup/install.sh

sos app scale set zookeeper 1
setops --stage sentry-production commit


# -- Clickhouse
# ---------------------------
setops --stage sentry-production app create clickhouse
setops --stage sentry-production app env set clickhouse MAX_MEMORY_USAGE_RATIO=0.3
sos app port set clickhouse 8123
sos app port set clickhouse 9000
setops --stage sentry-production commit


sos service link create clickhouse clickhouse --path /var/lib/clickhouse
sos service link create clickhouse-log clickhouse --path /var/log/clickhouse-server
sos commit

cd clickhouse
docker build -t zweitag.setops.net/sentry/production:clickhouse_1 .
docker push zweitag.setops.net/sentry/production:clickhouse_1
setops --stage sentry-production app release create clickhouse --digest
setops --stage sentry-production app release set clickhouse
setops --stage sentry-production commit


# -- Kafka
# ---------------------------
setops --stage sentry-production app create kafka
setops --stage sentry-production app env set kafka KAFKA_ZOOKEEPER_CONNECT="zookeeper.production.sentry.zweitagapps.internal"
setops --stage sentry-production app env set kafka KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://kafka.production.sentry.zweitagapps.internal:9092"
setops --stage sentry-production app env set kafka KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR="1"
setops --stage sentry-production app env set kafka KAFKA_OFFSETS_TOPIC_NUM_PARTITIONS="1"
setops --stage sentry-production app env set kafka KAFKA_LOG_RETENTION_HOURS="24"
setops --stage sentry-production app env set kafka KAFKA_MESSAGE_MAX_BYTES="50000000" #50MB or bust
setops --stage sentry-production app env set kafka KAFKA_MAX_REQUEST_SIZE="50000000" #50MB on requests apparently too
setops --stage sentry-production app env set kafka CONFLUENT_SUPPORT_METRICS_ENABLE="false"
setops --stage sentry-production app env set kafka KAFKA_LOG4J_LOGGERS="kafka.cluster=WARN,kafka.controller=WARN,kafka.coordinator=WARN,kafka.log=WARN,kafka.server=WARN,kafka.zookeeper=WARN,state.change.logger=WARN"
setops --stage sentry-production app env set kafka KAFKA_LOG4J_ROOT_LOGLEVEL="WARN"
setops --stage sentry-production app env set kafka KAFKA_TOOLS_LOG4J_LOGLEVEL="WARN"
sos app port set kafka 9092
setops --stage sentry-production commit

sos service link create kafka kafka --path /var/lib/kafka/data
sos service link create kafka-log kafka --path /var/lib/kafka/log
sos service link create sentry-secrets kafka --path /etc/kafka/secrets
sos commit

cd kafka
docker build -t zweitag.setops.net/sentry/production:kafka_1 .
docker push zweitag.setops.net/sentry/production:kafka_1
setops --stage sentry-production app release create kafka --digest
setops --stage sentry-production app release set kafka
setops --stage sentry-production commit

# -- Redis
# ---------------------------
setops --stage sentry-production app create redis
sos app port set redis 6379
setops --stage sentry-production commit

sos service link create redis redis --path /data
sos commit

docker pull redis:5.0-alpine
docker tag redis:5.0-alpine zweitag.setops.net/sentry/production:redis_1
docker push zweitag.setops.net/sentry/production:redis_1
setops --stage sentry-production app release create redis --digest
setops --stage sentry-production app release set redis
setops --stage sentry-production commit

# -- Memcached
# ---------------------------
setops --stage sentry-production app create memcached
sos app port set memcached 11211
setops --stage sentry-production commit

docker pull memcached:1.5-alpine
docker tag memcached:1.5-alpine zweitag.setops.net/sentry/production:memcached_1
docker push zweitag.setops.net/sentry/production:memcached_1
setops --stage sentry-production app release create memcached --digest
setops --stage sentry-production app release set memcached
setops --stage sentry-production commit



# -- Snuba
# ---------------------------

setops --stage sentry-production app create snuba-trans-clea
setops --stage sentry-production app env set snuba-trans-clea SNUBA_SETTINGS="docker"
setops --stage sentry-production app env set snuba-trans-clea CLICKHOUSE_HOST="clickhouse.production.sentry.zweitagapps.internal"
setops --stage sentry-production app env set snuba-trans-clea DEFAULT_BROKERS="kafka.production.sentry.zweitagapps.internal"
setops --stage sentry-production app env set snuba-trans-clea REDIS_HOST="redis.production.sentry.zweitagapps.internal"
setops --stage sentry-production app env set snuba-trans-clea UWSGI_MAX_REQUESTS="10000"
setops --stage sentry-production app env set snuba-trans-clea UWSGI_DISABLE_LOGGING="true"
setops --stage sentry-production app env set snuba-trans-clea SENTRY_EVENT_RETENTION_DAYS="90"
sos app port set snuba-trans-clea 1218
setops --stage sentry-production commit

# do it for every snuba container without cron context
docker pull getsentry/snuba:21.3.0
docker tag getsentry/snuba:21.3.0 zweitag.setops.net/sentry/production:snuba-trans-clea_1
docker push zweitag.setops.net/sentry/production:snuba-trans-clea_1
setops --stage sentry-production app release create snuba-trans-clea --digest
setops --stage sentry-production app release set snuba-trans-clea
setops --stage sentry-production commit

# do it for every snuba container with cron context
docker build --build-arg BASE_IMAGE=getsentry/snuba:21.3.0 -t zweitag.setops.net/sentry/production:snuba-trans-clea_1 ./cron/
docker push zweitag.setops.net/sentry/production:snuba-trans-clea_1
setops --stage sentry-production app release create snuba-trans-clea --digest
setops --stage sentry-production app release set snuba-trans-clea
setops --stage sentry-production commit


sos run snuba-api -- bootstrap --no-migrate --force
sos run snuba-api -- migrations migrate --force

sos run kafka --  /setup/install.sh




# -- symbolicator
# ---------------------------
setops --stage sentry-production app create symbolicator
sos service link create symbolicator symbolicator --path /data
sos app command set symbolicator -- "run -c /etc/symbolicator/config.yml"
setops --stage sentry-production commit


docker build --build-arg SYMBOLICATOR_IMAGE=getsentry/symbolicator:nightly -t zweitag.setops.net/sentry/production:symbolicator ./symbolicator/
docker push zweitag.setops.net/sentry/production:symbolicator
setops --stage sentry-production app release create symbolicator --digest
setops --stage sentry-production app release set symbolicator
setops --stage sentry-production commit


setops --stage sentry-production app create symbolic-cleanup
setops --stage sentry-production app create symbolic-cleanup
sos service link create symbolicator symbolic-cleanup --path /data
sos app command set symbolic-cleanup -- "55 23 * * * gosu symbolicator symbolicator cleanup"
setops --stage sentry-production commit

docker build --build-arg BASE_IMAGE=getsentry/symbolicator:nightly -t zweitag.setops.net/sentry/production:symbolic-cleanup ./cron/
docker push zweitag.setops.net/sentry/production:symbolic-cleanup
setops --stage sentry-production app release create symbolic-cleanup --digest
setops --stage sentry-production app release set symbolic-cleanup
setops --stage sentry-production commit


# -- GeoIPUpdate
# ---------------------------
setops --stage sentry-production app create geoipupdate
setops --stage sentry-production commit

cd geoip
docker build -t zweitag.setops.net/sentry/production:geoipupdate_1 .
docker push zweitag.setops.net/sentry/production:geoipupdate_1
setops --stage sentry-production app release create geoipupdate --digest
setops --stage sentry-production commit




# -- Sentry Images
# ---------------------------
setops --stage sentry-production app create web
setops --stage sentry-production commit

docker build -t zweitag.setops.net/sentry/production:web_1 .
docker push zweitag.setops.net/sentry/production:web_1

# Optional
setops --stage sentry-production app command set cron -- run cron

setops --stage sentry-production app release create web --digest
setops --stage sentry-production app release set web 1
setops --stage sentry-production commit

# -- Sentry
# web
# cron
# worker
# ingest-consumer
# proc-forwarder -> post-process-forwarder
# subscr-events -> subscription-consumer-events
# subscr-actions -> subscription-consumer-transactions


# -- Postgres
# ---------------------------
setops --stage sentry-production app create postgres
setops --stage sentry-production commit

docker pull postgres:9.6
docker tag postgres:9.6 zweitag.setops.net/sentry/production:postgres_1
docker push zweitag.setops.net/sentry/production:postgres_1
setops --stage sentry-production app env set postgres POSTGRES_HOST_AUTH_METHOD="trust"
setops --stage sentry-production app release create postgres --digest
setops --stage sentry-production app release set postgres 1
setops --stage sentry-production commit




docker build --build-arg RELAY_IMAGE=getsentry/snuba:nightly -f Dockerfile.snuba -t zweitag.setops.net/sentry/production:snuba .
docker build --build-arg RELAY_IMAGE=getsentry/relay:nightly -f Dockerfile.relay -t zweitag.setops.net/sentry/production:relay .




docker build --build-arg SYMBOLICATOR_IMAGE=getsentry/symbolicator:nightly -t zweitag.setops.net/sentry/production:symbolicator ./symbolicator/

docker build --build-arg SENTRY_IMAGE=getsentry/sentry:nightly -f Dockerfile.sentry -t zweitag.setops.net/sentry/production:sentry .
