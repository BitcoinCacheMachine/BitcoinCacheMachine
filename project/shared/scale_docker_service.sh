#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_MAX_INSTANCES=1

for i in "$@"; do
	case $i in
	--env-file-path=*)
		BCM_MAX_INSTANCES="${i#*=}"
		shift # past argument=value
		;;
	--stack-name=*)
		BCM_STACK_NAME="${i#*=}"
		shift # past argument=value
		;;
	--service-name=*)
		BCM_SERVICE_NAME="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ -z $BCM_STACK_NAME ]]; then
	echo "BCM_STACK_NAME cannot be empty."
	exit
fi

if [[ -z $BCM_SERVICE_NAME ]]; then
	echo "BCM_SERVICE_NAME cannot be empty."
	exit
fi

# let's scale the schema registry count to UP TO 3.
CLUSTER_NODE_COUNT=$(bcm cluster list --endpoints | wc -l)
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
	REPLICAS=$CLUSTER_NODE_COUNT

	if [[ $CLUSTER_NODE_COUNT -ge $BCM_MAX_INSTANCES ]]; then
		REPLICAS=$BCM_MAX_INSTANCES
	fi

	SERVICE_MODE=$(lxc exec bcm-gateway-01 -- docker service list --format "{{.Mode}}" --filter name="$BCM_STACK_NAME")
	if [[ $SERVICE_MODE == "replicated" ]]; then
		lxc exec bcm-gateway-01 -- docker service scale "$BCM_STACK_NAME""_""$BCM_SERVICE_NAME=$REPLICAS"
	fi
fi
