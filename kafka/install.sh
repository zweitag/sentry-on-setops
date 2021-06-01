#! /bin/sh
set -e

# NOTE: This step relies on `kafka` being available from the previous `snuba-api bootstrap` step
# XXX(BYK): We cannot use auto.create.topics as Confluence and Apache hates it now (and makes it very hard to enable)
kafka-topics --list --bootstrap-server kafka.production.sentry.zweitagapps.internal
EXISTING_KAFKA_TOPICS=$(kafka-topics --list --bootstrap-server kafka.production.sentry.zweitagapps.internal 2>/dev/null)
NEEDED_KAFKA_TOPICS="ingest-attachments ingest-transactions ingest-events"
for topic in $NEEDED_KAFKA_TOPICS; do
  if ! echo "$EXISTING_KAFKA_TOPICS" | grep -wq "$topic"; then
    kafka-topics --create --topic "$topic" --bootstrap-server kafka.production.sentry.zweitagapps.internal
    echo ""
  fi
done
