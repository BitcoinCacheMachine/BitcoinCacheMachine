#!/bin/bash

set -Eeuo pipefail

BCM_CLUSTER_PROVIDER=
BCM_CLUSTER_ENDPOINT_NAME=
BCM_ENDPOINT_VM_IP=

for i in "$@"; do
	case $i in
	--provider=*)
		BCM_CLUSTER_PROVIDER="${i#*=}"
		shift # past argument=value
		;;
	--endpoint-name=*)
		BCM_CLUSTER_ENDPOINT_NAME="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ $BCM_CLUSTER_PROVIDER == "multipass" ]]; then
	BCM_ENDPOINT_VM_IP=$(multipass list | grep "$BCM_CLUSTER_ENDPOINT_NAME" | awk '{ print $3 }')
fi

echo "$BCM_ENDPOINT_VM_IP"
