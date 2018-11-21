#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

KAFKA_IMAGE=
HOST_ENDING=
KAFKA_ZOOKEEPER_CONNECT=
KAFKA_ADVERTISED_LISTENERS=

for i in "$@"
do
case $i in
    --docker-image-name=*)
    KAFKA_IMAGE="${i#*=}"
    shift # past argument=value
    ;;
    --host-ending=*)
    HOST_ENDING="${i#*=}"
    shift # past argument=value
    ;;
    --zookeeper-connect=*)
    KAFKA_ZOOKEEPER_CONNECT="${i#*=}"
    shift # past argument=value
    ;;
    --advertised-listeners=*)
    KAFKA_ADVERTISED_LISTENERS="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


if [[ -z $KAFKA_IMAGE ]]; then
    echo "KAFKA_IMAGE is empty."
    exit
fi

if [[ -z $HOST_ENDING ]]; then
    echo "HOST_ENDING is empty."
    exit
fi

if [[ -z $KAFKA_ZOOKEEPER_CONNECT ]]; then
    echo "KAFKA_ZOOKEEPER_CONNECT is empty."
    exit
fi

if [[ -z $KAFKA_ADVERTISED_LISTENERS ]]; then
    echo "KAFKA_ADVERTISED_LISTENERS is empty."
    exit
fi


if ! lxc exec bcm-gateway-01 -- docker network list | grep "kafkanet" | grep "overlay" | grep -q "swarm"; then
    lxc exec bcm-gateway-01 -- docker network create --driver=overlay --attachable=true kafkanet
    sleep 5
fi

if lxc exec bcm-gateway-01 -- docker network list | grep -q "kafkanet"; then
    lxc exec bcm-gateway-01 -- env DOCKER_IMAGE=$KAFKA_IMAGE BROKER_ALIAS="broker-$(printf %02d $HOST_ENDING)" KAFKA_BROKER_ID="$HOST_ENDING" KAFKA_ZOOKEEPER_CONNECT="$KAFKA_ZOOKEEPER_CONNECT" KAFKA_ADVERTISED_LISTENERS=$KAFKA_ADVERTISED_LISTENERS  TARGET_HOST="bcm-kafka-$(printf %02d $HOST_ENDING)" docker stack deploy -c /root/stacks/kafka.yml "broker-$(printf %02d $HOST_ENDING)"
fi