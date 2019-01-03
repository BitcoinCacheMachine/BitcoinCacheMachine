#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/.env"

BCM_CLUSTER_NAME=
BCM_ENDPOINT_NAME=

for i in "$@"; do
	case $i in
	--cluster-name=*)
		BCM_CLUSTER_NAME="${i#*=}"
		shift # past argument=value
		;;
	--endpoint-name=*)
		BCM_ENDPOINT_NAME="${i#*=}"
		shift # past argument=value
		;;
	*) ;;
	esac
done

if [[ -z $BCM_CLUSTER_NAME ]]; then
	echo "BCM_CLUSTER_NAME not set. Exiting."
	exit
fi

# Ensure the endpoint name is in our env.
if env | grep -q "$BCM_ENDPOINT_NAME"; then
	echo "BCM_ENDPOINT_NAME variable not set."
	exit
fi

# shellcheck disable=2153
BCM_CLUSTER_DIR="$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME"
ENDPOINTS_DIR="$BCM_CLUSTER_DIR/endpoints"
BCM_ENDPOINT_DIR="$ENDPOINTS_DIR/$BCM_ENDPOINT_NAME"

if [[ $BCM_DEBUG == 1 ]]; then
	echo "BCM_CLUSTER_DIR: $BCM_CLUSTER_DIR"
	echo "ENDPOINTS_DIR: $ENDPOINTS_DIR"
	echo "BCM_ENDPOINT_DIR: $BCM_ENDPOINT_DIR"
fi

if [[ ! -f "$BCM_ENDPOINT_DIR/.env" ]]; then
	echo "WARNING: No $BCM_ENDPOINT_DIR/.env file exists to source."
else
	# shellcheck disable=1090
	source "$BCM_ENDPOINT_DIR/.env"

	if [[ $BCM_PROVIDER_NAME == "multipass" ]]; then
		# Stopping multipass vm $MULTIPASS_VM_NAME
		if multipass list | grep -q "$BCM_ENDPOINT_NAME"; then
			echo "Stopping multipass vm $BCM_ENDPOINT_NAME"
			sudo multipass stop $BCM_ENDPOINT_NAME
			sudo multipass delete $BCM_ENDPOINT_NAME
			sudo multipass purge
		else
			echo "$BCM_ENDPOINT_NAME doesn't exist."
		fi
	fi

	if [[ -d $BCM_ENDPOINT_DIR ]]; then
		rm -rf "$BCM_ENDPOINT_DIR"
	fi

	if lxc storage list | grep -q "bcm_btrfs"; then
		lxc storage delete bcm_btrfs
	fi
fi
