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

PREFIX="bcm-"
BCM_CLUSTER_NAME="$(lxc remote get-default)"
BCM_CLUSTER_NAME=${BCM_CLUSTER_NAME#"$PREFIX"}
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

if [[ "$BCM_CLI_VERB" == "list" ]]; then
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        if lxc info | grep -q "server_clustered: true"; then
            lxc cluster list | grep "$BCM_CLUSTER_NAME" | awk '{print $2}'
            exit
        fi
    fi
    
    lxc remote list --format csv | grep "bcm-" | awk -F "," '{print $1}' | awk '{print $1;}'
    
    exit
fi

if [[ $BCM_CLUSTER_NAME == "local" ]]; then
    echo "ERROR: BCM_CLUSTER_NAME was not defined. Set the cluster name with '--cluster-name='"
    exit
fi

if [[ -z $BCM_SSH_USERNAME ]]; then
    BCM_SSH_USERNAME=bcm
fi

if [[ -z $BCM_SSH_HOSTNAME ]]; then
    BCM_SSH_HOSTNAME="bcm-$BCM_CLUSTER_NAME-$(hostname)"
fi

if [[ $BCM_CLI_VERB == "create" ]]; then
    if bcm cluster list | grep -q "bcm-$BCM_CLUSTER_NAME"; then
        echo "The BCM Cluster 'bcm-$BCM_CLUSTER_NAME' already exists!"
        exit
    fi
    
    BCM_SSH_KEY_PATH="$BCM_WORKING_DIR/id_rsa_""$BCM_SSH_HOSTNAME"
    # let's generate a temporary SSH key if it doesn't exist.
    if [[ ! -f "$BCM_SSH_KEY_PATH" ]]; then
        # this key is for temporary use and used only during initial provisioning.
        ssh-keygen -t rsa -b 4096 -C "bcm@$BCM_SSH_HOSTNAME" -f "$BCM_SSH_KEY_PATH" -N ""
        chmod 400 "$BCM_SSH_KEY_PATH.pub"
    fi
    
    # first check to ensure that the cluster doesn't already exist.
    if ! lxc remote list | grep -q "$BCM_CLUSTER_NAME"; then
        bash -c "$BCM_GIT_DIR/cluster/up_cluster_master.sh --driver=$BCM_DRIVER --cluster-name=$BCM_CLUSTER_NAME --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME --ssh-key-path=$BCM_SSH_KEY_PATH"
    else
        echo "ERROR: BCM cluster 'BCM_CLUSTER_NAME' already exists!"
        exit
    fi
fi

if [[ $BCM_CLI_VERB == "destroy" ]]; then
    if ! bcm cluster list | grep -q "bcm-$BCM_CLUSTER_NAME"; then
        echo "WARNING: The BCM Cluster 'bcm-$BCM_CLUSTER_NAME' doesn't appear to exist!"
    fi
    
    if [[ $BCM_DRIVER == multipass ]]; then
        VM_NAME="bcm-$BCM_CLUSTER_NAME-$(hostname)"
        if multipass list | grep -q "$VM_NAME"; then
            multipass stop "$VM_NAME"
            multipass delete "$VM_NAME"
            multipass delete "$VM_NAME"
        fi
        
        multipass purge
        
        # remove the entry for the host in your BCM_KNOWN_HOSTS_FILE
        ssh-keygen -f "$BCM_KNOWN_HOSTS_FILE" -R "$VM_NAME"
    fi
    
    # if the LXC remote for the cluster doesn't exist, then we'll state as such and quit.
    # if it's the cluster master add the LXC remote so we can manage it.
    if ! lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
        echo "WARNING: LXC REMOTE '$BCM_CLUSTER_NAME' doesn't exist. Can't delete."
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
    
    # update the SDN controller's /etc/hosts file if it's a multipass VM.
    if [[ $BCM_DRIVER == multipass ]]; then
        bash -c "$BCM_GIT_DIR/cli/shared/update_controller_etc_hosts.sh"
    fi
    
    echo "The BCM cluster '$BCM_CLUSTER_NAME' and associated artifacts have been removed."
fi
