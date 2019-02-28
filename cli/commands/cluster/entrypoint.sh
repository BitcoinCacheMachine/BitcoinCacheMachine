#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_HELP_FLAG=0

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

if ! snap list | grep -q lxd; then
    bash -c "$BCM_GIT_DIR/cli/commands/install/snap_install_lxd_local.sh"
fi

BCM_CLUSTER_NAME="$(lxc remote get-default)"
BCM_ENDPOINTS_FLAG=0
BCM_DRIVER=ssh
BCM_SSH_HOSTNAME=
BCM_SSH_USERNAME=

for i in "$@"; do
    case $i in
        --driver=*)
            BCM_DRIVER="${i#*=}"
            shift # past argument=value
        ;;
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


if [[ $BCM_DRIVER != "ssh" && $BCM_DRIVER != "multipass" ]]; then
    echo "ERROR: BCM Cluster driver MUST be 'ssh' or 'multipass'."
    exit
fi


if [[ $BCM_CLUSTER_NAME == "local" ]]; then
    echo "ERROR: BCM_CLUSTER_NAME was not defined. Set the cluster name with '--cluster-name='"
    exit
fi

if [[ $BCM_CLI_VERB == "create" ]]; then
    # if the BCM_DRIVER is multipass, then we assume the remote endpoint doesn't
    # exist and we need to create it via multipass. Once there's an SSH service available
    # on that endpoint, we can continue.
    if [[ $BCM_DRIVER == multipass ]]; then
        BCM_SSH_USERNAME="bcm"
        BCM_SSH_HOSTNAME="$BCM_CLUSTER_NAME-$(hostname)"
        
        bash -c "$BCM_GIT_DIR/cluster/new_multipass_vm.sh --vm-name=$BCM_SSH_HOSTNAME"
        
        # update the hostname to its avahi daemon name.
        BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME.local"
    fi
    
    # first check to ensure that the cluster doesn't already exist.
    if ! lxc remote list | grep -q "$BCM_CLUSTER_NAME"; then
        bash -c "$BCM_GIT_DIR/cluster/up_cluster_master.sh --cluster-name=$BCM_CLUSTER_NAME --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME"
    else
        echo "ERROR: BCM Cluster with name 'BCM_CLUSTER_NAME' already exists!"
        exit
    fi
    
    elif [[ $BCM_CLI_VERB == "destroy" ]]; then
    
    if [[ $BCM_DRIVER == multipass ]]; then
        VM_NAME="$BCM_CLUSTER_NAME-$(hostname)"
        if multipass list | grep -q "$VM_NAME"; then
            multipass stop "$VM_NAME"
            multipass delete "$VM_NAME"
            multipass delete "$VM_NAME"
        fi
        
        multipass purge
    fi
    
    
    # if the LXC remote for the cluster doesn't exist, then we'll state as such and quit.
    # if it's the cluster master add the LXC remote so we can manage it.
    if ! lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
        echo "WARNING: LXC REMOTE '$BCM_CLUSTER_NAME' doesn't exist. Can't delete."
        exit
    fi
    
    # if the user didn't pass the cluster name, then we assume the user wants to delete the active cluster.
    CHOICE=n
    if [[ -z "$BCM_CLUSTER_NAME" ]]; then
        read -rp "WARNING: Cluster name not specified. Do you want to delete the currently active cluster of $(lxc remote get-default) (y/n):"  CHOICE
        if [[ $CHOICE == "y" ]]; then
            BCM_CLUSTER_NAME="$(lxc remote get-default)"
        fi
    fi
    
    export BCM_CLUSTER_NAME="$BCM_CLUSTER_NAME"
    
    bash -c "$BCM_GIT_DIR/cluster/destroy_cluster_master.sh --cluster-name=$BCM_CLUSTER_NAME  --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME"
    
    elif [[ "$BCM_CLI_VERB" == "list" ]]; then
    export BCM_CLUSTER_NAME="$BCM_CLUSTER_NAME"
    
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        if lxc info | grep -q "server_clustered: true"; then
            lxc cluster list | grep "$BCM_CLUSTER_NAME" | awk '{print $2}'
        fi
    else
        echo
    fi
else
    cat ./help.txt
fi