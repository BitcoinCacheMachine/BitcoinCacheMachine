#!/bin/bash

set -Eeuox pipefail

BCM_DEPLOY_ALL=0
BCM_DEPLOY_STACK_KAFKA_SCHEMA_REGISTRY=0
BCM_DEPLOY_STACK_KAFKA_REST=0
BCM_DEPLOY_STACK_KAFKA_CONNECT=0

for i in "$@"
do
case $i in
    --schemareg)
     BCM_DEPLOY_STACK_KAFKA_SCHEMA_REGISTRY=1
    shift # past argument=value
    ;;
    --rest)
    BCM_DEPLOY_STACK_KAFKA_REST=1
    shift # past argument=value
    ;;
    --connect)
    BCM_DEPLOY_STACK_KAFKA_CONNECT=1
    shift # past argument=value
    ;;
    --all)
    BCM_DEPLOY_ALL=1
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ $BCM_DEPLOY_ALL = 1 ]]; then
    BCM_DEPLOY_STACK_KAFKA_SCHEMA_REGISTRY=1
    BCM_DEPLOY_STACK_KAFKA_REST=1
    BCM_DEPLOY_STACK_KAFKA_CONNECT=1
fi


export BCM_DEPLOY_STACK_KAFKA_SCHEMA_REGISTRY=$BCM_DEPLOY_STACK_KAFKA_SCHEMA_REGISTRY
export BCM_DEPLOY_STACK_KAFKA_REST=$BCM_DEPLOY_STACK_KAFKA_REST
export BCM_DEPLOY_STACK_KAFKA_CONNECT=$BCM_DEPLOY_STACK_KAFKA_CONNECT