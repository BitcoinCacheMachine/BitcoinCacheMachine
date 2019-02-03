#!/bin/bash


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
# 				./up_cluster_enadpoint.sh --cluster-name=$BCM_CLUSTER_NAME --endpoint-name="$BCM_ENDPOINT_NAME" --endpoint-dir="$BCM_CLUSTER_ENDPOINT_DIR"
# 			fi
# 		fi
# 	done
# fi