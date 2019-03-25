#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

IS_MASTER=0
BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=
BCM_DRIVER=ssh
ENDPOINT_DIR=
MACVLAN_INTERFACE=

for i in "$@"; do
    case $i in
        --master)
            IS_MASTER=1
            shift # past argument=value
        ;;
        --ssh-username=*)
            BCM_SSH_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-hostname=*)
            BCM_SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --endpoint-dir=*)
            ENDPOINT_DIR="${i#*=}"
            shift # past argument=value
        ;;
        --macvlan-interface=*)
            MACVLAN_INTERFACE="${i#*=}"
            shift # past argument=value
        ;;
        --driver=*)
            BCM_DRIVER="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "ERROR: BCM_SSH_USERNAME not passed correctly."
    exit
fi

if [[ -z "$BCM_SSH_HOSTNAME" ]]; then
    echo "ERROR: BCM_SSH_HOSTNAME not passed correctly."
    exit
fi

if [[ ! -d "$ENDPOINT_DIR" ]]; then
    echo "ERROR: ENDPOINT_DIR does not exist."
    exit
fi

BCM_LXD_SECRET="$(apg -n 1 -m 30 -M CN)"
export BCM_LXD_SECRET="$BCM_LXD_SECRET"
export BCM_SSH_USERNAME="$BCM_SSH_USERNAME"
export BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"

if [[ $BCM_DRIVER == "multipass" ]]; then
    MACVLAN_INTERFACE=ens3
fi

PHYSICAL_UNDERLAY_INTERFACE=
OUTSIDE_INTERFACE=

export MACVLAN_INTERFACE="$MACVLAN_INTERFACE"
export PHYSICAL_UNDERLAY_INTERFACE="$PHYSICAL_UNDERLAY_INTERFACE"
export OUTSIDE_INTERFACE="$OUTSIDE_INTERFACE"
export BCM_DRIVER="$BCM_DRIVER"

touch "$ENDPOINT_DIR/env"
if [ $IS_MASTER -eq 1 ]; then
    envsubst <./envtemplates/master_defaults.env >"$ENDPOINT_DIR/env"
    elif [ $IS_MASTER -ne 1 ]; then
    envsubst <./envtemplates/member_defaults.env >"$ENDPOINT_DIR/env"
else
    echo "Incorrect usage. Please specify whether '$BCM_SSH_HOSTNAME' is an LXD cluster master or member."
fi

LXD_SERVER_NAME="$BCM_SSH_HOSTNAME"
if [ $IS_MASTER -eq 1 ]; then
    # these two lines are so that ssh hosts can have the correct naming convention for LXD node info.
    if [[ ! "$LXD_SERVER_NAME" == *"-01"* ]]; then
        LXD_SERVER_NAME="$LXD_SERVER_NAME-01"
    fi
    
    if [[ ! "$LXD_SERVER_NAME" == *"bcm-"* ]]; then
        LXD_SERVER_NAME="bcm-$LXD_SERVER_NAME"
    fi
    
    export LXD_SERVER_NAME="$LXD_SERVER_NAME"
    envsubst <./lxd_preseed/lxd_master_preseed.yml >"$ENDPOINT_DIR/lxd_preseed.yml"
    elif [ $IS_MASTER -ne 1 ]; then
    envsubst <./lxd_preseed/lxd_member_preseed.yml >"$ENDPOINT_DIR/lxd_preseed.yml"
else
    echo "Incorrect usage. Please specify whether '$BCM_SSH_HOSTNAME' is an LXD cluster master or member."
    exit
fi
