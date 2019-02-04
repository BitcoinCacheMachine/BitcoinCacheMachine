#!/bin/bash

set -o nounset
cd "$(dirname "$0")"

BCM_HELP_FLAG=0

VALUE=${2:-}
if [ ! -z ${VALUE} ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

BCM_CLUSTER_NAME=
BCM_ENDPOINTS_FLAG=0
BCM_SSH_HOSTNAME=
BCM_SSH_USERNAME=

for i in "$@"; do
    case $i in
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-hostname=*)
            BCM_SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-username=*)
            BCM_SSH_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --endpoints)
            BCM_ENDPOINTS_FLAG=1
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ -z $BCM_CLUSTER_NAME ]]; then
    BCM_CLUSTER_NAME=$(lxc remote get-default)
fi

if [[ $BCM_CLI_VERB == "create" ]]; then
    bash -c "$BCM_GIT_DIR/cluster/up_cluster_master.sh --cluster-name=$BCM_CLUSTER_NAME --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME"
    elif [[ $BCM_CLI_VERB == "destroy" ]]; then
    
    bcm project 
    
    # if the user didn't pass the cluster name, then we assume the user wants to delete the active cluster.
    CHOICE=n
    if [[ -z "$BCM_CLUSTER_NAME" ]]; then
        read -rp "WARNING: Cluster name not specified. Do you want to delete the currently active cluster of $(lxc remote get-default) (y/n):"  CHOICE
        if [[ $CHOICE == "y" ]]; then
            BCM_CLUSTER_NAME="$(lxc remote get-default)"
        fi
    fi
    
    export BCM_CLUSTER_NAME="$BCM_CLUSTER_NAME"
    
    # let's not delete the locally installed LXD instance.
    if [[ $BCM_CLUSTER_NAME != "local" ]]; then
        bash -c "$BCM_GIT_DIR/cluster/destroy_cluster_master.sh --cluster-name=$BCM_CLUSTER_NAME  --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME"
    else
        # delete the items associated with the lxd_preseed.yml
        if sudo lxc profile list | grep -q "bcm_default"; then
            sudo lxc profile delete bcm_default
        fi
        
        if sudo lxc storage list | grep -q "bcm_btrfs"; then
            sudo lxc storage delete bcm_btrfs
        fi
    fi
    
    elif [[ $BCM_CLI_VERB == "list" ]]; then
    export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
    
    # shellcheck disable=SC2153
    export BCM_ENDPOINTS_FLAG=$BCM_ENDPOINTS_FLAG
    
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        
        if lxc info | grep -q "server_clustered: true"; then
            lxc cluster list | grep "$BCM_CLUSTER_NAME" | awk '{print $2}'
        fi
    fi
else
    cat ./help.txt
fi