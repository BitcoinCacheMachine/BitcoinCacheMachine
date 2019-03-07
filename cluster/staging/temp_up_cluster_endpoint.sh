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
