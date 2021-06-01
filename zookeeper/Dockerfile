FROM confluentinc/cp-zookeeper:5.5.0

COPY ./snapshot.0 /temp/snapshot.0

COPY ./install.sh /setup/install.sh

ENV ZOOKEEPER_SNAPSHOT_TRUST_EMPTY=true
