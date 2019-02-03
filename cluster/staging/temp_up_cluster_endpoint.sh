#!/bin/bash

# prepare the cloud-init file
if [[ $BCM_PROVIDER_NAME != "local" ]]; then
    if [[ -f $BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml ]]; then
        BCM_CLUSTER_MASTER_LXD_PRESEED=$(awk '{print "      " $0}' "$BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml")
        export BCM_CLUSTER_MASTER_LXD_PRESEED
        
        BCM_LISTEN_INTERFACE=
        if [[ $BCM_PROVIDER_NAME == "multipass" ]]; then
            BCM_LISTEN_INTERFACE=ens3
        fi
        
        export BCM_LISTEN_INTERFACE=$BCM_LISTEN_INTERFACE
        envsubst <./cloud_init_template.yml >"$BCM_CLUSTER_ENDPOINT_DIR/cloud-init.yml"
    fi
fi

# if [[ $BCM_PROVIDER_NAME == "multipass" ]]; then
# 	## launch the VM based with a static cloud-init.
# 	# we'll create lxd preseed files AFTER boot so we know the IP address.
# 	multipass launch \
# 		--disk "$BCM_ENDPOINT_DISK_SIZE" \
# 		--mem "$BCM_ENDPOINT_MEM_SIZE" \
# 		--cpus "$BCM_ENDPOINT_CPU_COUNT" \
# 		--name "$BCM_ENDPOINT_NAME" \
# 		--cloud-init "$BCM_CLUSTER_ENDPOINT_DIR/cloud-init.yml" \
# 		cosmic
# fi



#### THIS IS PART OF THE DESTRY SCRIPT FOR CLUSTER ENDPOINT

echo "TODO DESTROY_CLUSTER_ENDPOINT"
# if [[ ! -f "$BCM_ENDPOINT_DIR/env" ]]; then
# 	echo "WARNING: No $BCM_ENDPOINT_DIR/env file exists to source."
# else
# 	# shellcheck disable=1090
# 	source "$BCM_ENDPOINT_DIR/env"

# 	if [[ $BCM_PROVIDER_NAME == "multipass" ]]; then
# 		# Stopping multipass vm $MULTIPASS_VM_NAME
# 		if multipass list | grep -q "$BCM_ENDPOINT_NAME"; then
# 			echo "Stopping multipass vm $BCM_ENDPOINT_NAME"
# 			sudo multipass stop $BCM_ENDPOINT_NAME
# 			sudo multipass delete $BCM_ENDPOINT_NAME
# 			sudo multipass purge
# 		else
# 			echo "$BCM_ENDPOINT_NAME doesn't exist."
# 		fi
# 	fi
# fi