#!/bin/bash

set -Eeuo pipefail

BCM_CLUSTER_ENDPOINT_NAME=
BCM_ENDPOINT_VM_IP=
BCM_LXD_SECRET=

for i in "$@"; do
	case $i in
	--cluster-name=*)
		BCM_CLUSTER_NAME="${i#*=}"
		shift # past argument=value
		;;
	--endpoint=*)
		BCM_CLUSTER_ENDPOINT_NAME="${i#*=}"
		shift # past argument=value
		;;
	--endpoint-ip=*)
		BCM_ENDPOINT_VM_IP="${i#*=}"
		shift # past argument=value
		;;
	--endpoint-lxd-secret=*)
		BCM_LXD_SECRET="${i#*=}"
		shift # past argument=value
		;;
	--provider=*)
		BCM_PROVIDER_NAME="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ -z $BCM_CLUSTER_ENDPOINT_NAME ]]; then
	echo "BCM_CLUSTER_ENDPOINT_NAME not set. Exiting"
	exit
fi

if [[ -z $BCM_LXD_SECRET ]]; then
	echo "BCM_LXD_SECRET not set. Exiting"
	exit
fi

# first let's make sure we have
bash -c "$BCM_GIT_DIR/cluster/providers/lxd/snap_lxd_install.sh"

if [[ $BCM_PROVIDER_NAME == "baremetal" ]]; then
	# to do, update this to multiple baremetals...
	BCM_ENDPOINT_VM_IP="127.0.10.1"
fi

if [[ -z $BCM_ENDPOINT_VM_IP ]]; then
	echo "BCM_ENDPOINT_VM_IP not set. Exiting"
	exit
fi

echo "Waiting for the remote lxd daemon to become available at $BCM_ENDPOINT_VM_IP."
wait-for-it -t 0 "$BCM_ENDPOINT_VM_IP:8443"

echo "Adding a lxd remote for $BCM_CLUSTER_ENDPOINT_NAME at $BCM_ENDPOINT_VM_IP:8443."
lxc remote add $BCM_CLUSTER_NAME "$BCM_ENDPOINT_VM_IP:8443" --accept-certificate --password="$BCM_LXD_SECRET"
lxc remote switch $BCM_CLUSTER_NAME
echo "Current lxd remote default is $BCM_CLUSTER_NAME."
