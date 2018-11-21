#!/bin/bash

# set -Eeuo pipefail

# BCM_CLUSTER_ENDPOINT_NAME=$1
# ENDPOINTS_DIR=$2
# BCM_LXD_CLUSTER_MASTER=$3
# BCM_LXD_CLUSTER_MASTER_PASSWORD=$4
# BCM_LXD_CLUSTER_MASTER_IP=

# #let's update our ENV to include the appropriate information from the
# #LXD cluster master. Grab the info then switch back to the new VM that we're creating.
# export CLUSTER_MASTER_ENV_DIR=$ENDPOINTS_DIR/$BCM_LXD_CLUSTER_MASTER
# source $CLUSTER_MASTER_ENV_DIR/.env
# export BCM_ENDPOINT_DIR=$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME
# source $BCM_ENDPOINT_DIR/.env

# export BCM_LXD_CLUSTER_MASTER_IP=$(multipass list | grep "$BCM_LXD_CLUSTER_MASTER" | awk '{ print $3 }')

# CERT_TEMP_FILE=$BCM_ENDPOINT_DIR/cert.txt.tmp
# touch $CERT_TEMP_FILE
# echo "-----BEGIN CERTIFICATE-----" > $CERT_TEMP_FILE
# echo "" >> $CERT_TEMP_FILE
# grep -v '\-\-\-\-\-' $CLUSTER_MASTER_ENV_DIR/lxd/lxd.cert | sed ':a;N;$!ba;s/\n/\n\n/g' | sed 's/^/      /' >> $CERT_TEMP_FILE
# echo "" >> $CERT_TEMP_FILE
# echo "      -----END CERTIFICATE-----" >> $CERT_TEMP_FILE
# echo "" >> $CERT_TEMP_FILE

# export BCM_LXD_CLUSTER_CERTIFICATE=$(cat $CERT_TEMP_FILE)
# mkdir -p $BCM_ENDPOINT_DIR/lxd
# envsubst < ./lxd_preseed/lxd_member_preseed.yml > $BCM_ENDPOINT_DIR/lxd/preseed.yml

# # upload the lxd preseed file to the multipass vm.
# multipass copy-files $BCM_ENDPOINT_DIR/lxd/preseed.yml $BCM_CLUSTER_ENDPOINT_NAME:/home/multipass/preseed.yml

# # now initialize the LXD daemon on the VM.
# multipass exec $BCM_CLUSTER_ENDPOINT_NAME -- sh -c "cat /home/multipass/preseed.yml | sudo lxd init --preseed"

