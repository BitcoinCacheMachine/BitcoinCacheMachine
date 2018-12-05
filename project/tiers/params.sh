#!/bin/bash

set -Eeuo pipefail

BCM_DEPLOY_TIER_ALL=0
BCM_DEPLOY_GATEWAY=0
BCM_DEPLOY_TIER_KAFKA=0
BCM_DEPLOY_TIER_UI=0
BCM_DEPLOY_TIER_BITCOIN=0

for i in "$@"
do
case $i in
    --gateway)
     BCM_DEPLOY_GATEWAY=1
    shift # past argument=value
    ;;
    --kafka)
    BCM_DEPLOY_TIER_KAFKA=1
    shift # past argument=value
    ;;
    --ui)
    BCM_DEPLOY_TIER_UI=1
    shift # past argument=value
    ;;
    --bitcoin)
    BCM_DEPLOY_TIER_BITCOIN=1
    shift # past argument=value
    ;;
    --all)
    BCM_DEPLOY_TIER_ALL=1
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ $BCM_DEPLOY_TIER_ALL = 1 ]]; then
    BCM_DEPLOY_GATEWAY=1
    BCM_DEPLOY_TIER_KAFKA=1
    BCM_DEPLOY_TIER_UI=1
    BCM_DEPLOY_TIER_BITCOIN=1
fi


export BCM_DEPLOY_GATEWAY=$BCM_DEPLOY_GATEWAY
export BCM_DEPLOY_TIER_KAFKA=$BCM_DEPLOY_TIER_KAFKA
export BCM_DEPLOY_TIER_UI=$BCM_DEPLOY_TIER_UI
export BCM_DEPLOY_TIER_BITCOIN=$BCM_DEPLOY_TIER_BITCOIN