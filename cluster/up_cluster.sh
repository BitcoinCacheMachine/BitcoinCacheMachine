#!/bin/bash

# brings up LXD cluster of at least 1 member. Increase the number
# by providing $1 as a number 2 or above.

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLUSTER_NODE_COUNT=
BCM_CLUSTER_NAME=
BCM_CLUSTER_MASTER_NAME=

for i in "$@"; do
    case $i in
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --node-count=*)
            BCM_CLUSTER_NODE_COUNT="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

export TEMP_DIR="/tmp/bcm/$BCM_CLUSTER_NAME"
mkdir -p "$TEMP_DIR"

export BCM_ENDPOINT_NAME="$BCM_CLUSTER_NAME-01"
BCM_CLUSTER_MASTER_NAME="$BCM_ENDPOINT_NAME"

export ENV_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/env"
./stub_env.sh --endpoint-name="$BCM_CLUSTER_MASTER_NAME" --master

# create the endpoint using the underlying provider
./up_cluster_endpoint.sh --master --cluster-name="$BCM_CLUSTER_NAME" --endpoint-name="$BCM_ENDPOINT_NAME"

# since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
LXD_CERT_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd.cert"

# makre sure we're on the correct LXC remote
if [[ $(lxc remote get-default) == "$BCM_CLUSTER_NAME" ]]; then
    # get the cluster master certificate using LXC.
    touch "$LXD_CERT_FILE"
    lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \\t]*//" >>"$LXD_CERT_FILE"
fi


# #########################################
# # create the other members of the cluster.
# # now provision the other nodes.
# if [[ $BCM_CLUSTER_NODE_COUNT -ge 2 ]]; then

# 	# let's the the BCM_LXD_SECRET from the master.
# 	# shellcheck source=/dev/null
# 	source "$TEMP_DIR/env"
# 	export BCM_LXD_CLUSTER_MASTER_PASSWORD=$BCM_LXD_SECRET

# 	if [[ -f $TEMP_DIR/lxd.cert ]]; then
# 		BCM_LXD_CLUSTER_CERTIFICATE=$(sed ':a;N;$!ba;s/\n/\n\n/g' "$TEMP_DIR/lxd.cert")
# 		export BCM_LXD_CLUSTER_CERTIFICATE
# 	else
# 		echo "$TEMP_DIR/lxd.cert does not exist. Cannot create additional cluster members."
# 	fi

# 	# spin up some member nodes
# 	echo "Member Count: $BCM_CLUSTER_NODE_COUNT"
# 	for i in $(seq -f %02g 2 $BCM_CLUSTER_NODE_COUNT); do
# 		echo "$BCM_CLUSTER_NAME-$i"
# 		export BCM_ENDPOINT_NAME="$BCM_CLUSTER_NAME-$i"
# 		bash -c "./stub_env.sh --endpoint-name=$BCM_ENDPOINT_NAME --endpoint-type=member"

# 		if [[ -f $ENV_FILE ]]; then
# 			PRESEED_FILE=./lxd_preseed/lxd_member_preseed.yml
# 			if [[ -f $PRESEED_FILE ]]; then
# 				envsubst <./lxd_preseed/lxd_member_preseed.yml >"$BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml"
# 				# create the endpoint using the underlying provider
# 				./up_cluster_endpoint.sh --cluster-name=$BCM_CLUSTER_NAME --endpoint-name="$BCM_ENDPOINT_NAME" --endpoint-dir="$BCM_CLUSTER_ENDPOINT_DIR"
# 			fi
# 		fi
# 	done
# fi