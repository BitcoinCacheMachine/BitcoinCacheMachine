#!/bin/bash

set -eu
cd "$(dirname "$0")"

ZOOKEEPER_IMAGE=
HOST_ENDING=
KAFKA_HOSTNAME=
ZOOKEEPER_SERVERS=

for i in "$@"
do
case $i in
    --docker-image-name=*)
    ZOOKEEPER_IMAGE="${i#*=}"
    shift # past argument=value
    ;;
    --host-ending=*)
    HOST_ENDING="${i#*=}"
    shift # past argument=value
    ;;
    --target-host=*)
    KAFKA_HOSTNAME="${i#*=}"
    shift # past argument=value
    ;;
    --zookeeper-servers=*)
    ZOOKEEPER_SERVERS="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


if [[ -z $ZOOKEEPER_IMAGE ]]; then
    echo "ZOOKEEPER_IMAGE is empty."
    exit
fi

if [[ -z HOST_ENDING ]]; then
    echo "HOST_ENDING is empty."
    exit
fi

if [[ -z KAFKA_HOSTNAME ]]; then
    echo "KAFKA_HOSTNAME is empty."
    exit
fi

if [[ -z ZOOKEEPER_SERVERS ]]; then
    echo "ZOOKEEPER_SERVERS is empty."
    exit
fi

if [[ $HOST_ENDING = 1 ]]; then
    STACK_FILE=zookeeper_master.yml
elif [[ $HOST_ENDING -ge 2 ]]; then
    STACK_FILE=zookeeper_member.yml
fi

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$ZOOKEEPER_IMAGE" ZOOKEEPER_HOSTNAME="zookeeper-$(printf %02d $HOST_ENDING)" OVERLAY_NETWORK_NAME="zookeeper-$(printf %02d $HOST_ENDING)" TARGET_HOST="$KAFKA_HOSTNAME" ZOOKEPER_ID="$HOST_ENDING" ZOOKEEPER_SERVERS="$ZOOKEEPER_SERVERS" docker stack deploy -c /root/stacks/$STACK_FILE "zookeeper-$(printf %02d $HOST_ENDING)"