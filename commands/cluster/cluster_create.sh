#!/bin/bash



set -Eeuo pipefail
cd "$(dirname "$0")"


# # since we're doing a local install; we can just connect our wirepoint
# # endpoint listening service on the same interface being used for our
# # default route. TODO; add CLI option to specify address.
# MACVLAN_INTERFACE="$(ip route | grep default | cut -d " " -f 5)"
# IP_OF_MACVLAN_INTERFACE="$(ip addr show "$MACVLAN_INTERFACE" | grep "inet " | cut -d/ -f1 | awk '{print $NF}')"
# BCM_LXD_SECRET="$(apg -n 1 -m 30 -M CN)"
# export BCM_LXD_SECRET="$BCM_LXD_SECRET"
# export MACVLAN_INTERFACE="$MACVLAN_INTERFACE"
# LXD_SERVER_NAME="$(hostname)"
# # these two lines are so that ssh hosts can have the correct naming convention for LXD node info.
# if [[ ! "$LXD_SERVER_NAME" == *"-01"* ]]; then
#     LXD_SERVER_NAME="$LXD_SERVER_NAME-01"
# fi

# if [[ ! "$LXD_SERVER_NAME" == *"bcm-"* ]]; then
#     LXD_SERVER_NAME="bcm-$LXD_SERVER_NAME"
# fi

# export LXD_SERVER_NAME="$LXD_SERVER_NAME"
# export IP_OF_MACVLAN_INTERFACE="$IP_OF_MACVLAN_INTERFACE"
# PRESEED_YAML="$(envsubst <./lxd_preseed/lxd_master_preseed.yml)"
# sudo bash -c "$BCM_GIT_DIR/commands/install/endpoint_provision.sh --yaml-text='$PRESEED_YAML'"