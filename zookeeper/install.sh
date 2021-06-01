#! /bin/sh
set -e

ZOOKEEPER_SNAPSHOT_FOLDER_EXISTS=$(bash -c 'ls 2>/dev/null -Ubad1 -- /var/lib/zookeeper/data/version-2 | wc -l | tr -d '[:space:]'')
printf "ZOOKEEPER_SNAPSHOT_FOLDER_EXISTS: $ZOOKEEPER_SNAPSHOT_FOLDER_EXISTS"
if [ "$ZOOKEEPER_SNAPSHOT_FOLDER_EXISTS" -eq 1 ]; then
  ZOOKEEPER_LOG_FILE_COUNT=$(bash -c 'ls 2>/dev/null -Ubad1 -- /var/lib/zookeeper/log/version-2/* | wc -l | tr -d '[:space:]'')
  printf "ZOOKEEPER_LOG_FILE_COUNT: $ZOOKEEPER_LOG_FILE_COUNT"
  ZOOKEEPER_SNAPSHOT_FILE_COUNT=$(bash -c 'ls 2>/dev/null -Ubad1 -- /var/lib/zookeeper/data/version-2/* | wc -l | tr -d '[:space:]'')
  printf "ZOOKEEPER_SNAPSHOT_FILE_COUNT: $ZOOKEEPER_SNAPSHOT_FILE_COUNT"
  # This is a workaround for a ZK upgrade bug: https://issues.apache.org/jira/browse/ZOOKEEPER-3056
  if [ "$ZOOKEEPER_LOG_FILE_COUNT" -gt 0 ] && [ "$ZOOKEEPER_SNAPSHOT_FILE_COUNT" -eq 0 ]; then
    printf "Copying Zookeeper snapshot file"
    bash -c 'cp /temp/snapshot.0 /var/lib/zookeeper/data/version-2/snapshot.0'
  fi
fi
