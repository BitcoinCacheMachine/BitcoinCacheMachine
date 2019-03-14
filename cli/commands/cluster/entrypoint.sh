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

CLUSTER_NAME="$(lxc remote get-default)"
BCM_ENDPOINTS_FLAG=0
BCM_DRIVER=multipass
BCM_SSH_HOSTNAME=
BCM_SSH_USERNAME=

for i in "$@"; do
    case $i in
        --driver=*)
            BCM_DRIVER="${i#*=}"
            shift # past argument=value
        ;;
        --cluster-name=*)
            CLUSTER_NAME="${i#*=}"
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

if [[ "$BCM_CLI_VERB" == "list" ]]; then
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        lxc cluster list | grep "$CLUSTER_NAME" | awk '{print $2}'
        exit
    fi
    
    lxc remote list --format csv | grep "bcm-" | awk -F "," '{print $1}' | awk '{print $1}'
    
    exit
fi

if [[ $BCM_DRIVER != "ssh" && $BCM_DRIVER != "multipass" ]]; then
    echo "ERROR: BCM Cluster driver MUST be 'ssh' or 'multipass'."
    exit
fi

if [[ $BCM_DRIVER == "multipass" ]]; then
    # Check to see if the computer has hardware virtualization support. If not, then we
    # switch our driver to SSH.
    if ! lscpu | grep "Virtualization:" | cut -d ":" -f 2 | xargs | grep -q "VT-x"; then
        echo "Your computer does NOT support hardware virtualization. You may need to turn this feature on in the BIOS. BCM will be deployed to your machine in a baremetal configuration."
        BCM_DRIVER=ssh
        BCM_SSH_HOSTNAME="bcm-$(hostname)"
        BCM_SSH_USERNAME="$(whoami)"
    else
        BCM_SSH_HOSTNAME="bcm-$(hostname)"
        
        # Next make sure multipass is installed so we can run type-1 VMs
        if ! snap list | grep -q multipass; then
            # if it doesn't, let's install
            echo "Performing a local LXD installation using multipass. Note this provides no fault tolerance."
            sudo snap install multipass --beta --classic
            sleep 10
        fi
    fi
fi

# if the cluster name is local, then we assume the user hasn't overridden
# what was set in 'lxc remote get-default'. If so, we will assume a cluster
# will be created with the name of `bcm-hostname`
if [[ $CLUSTER_NAME == "local" ]]; then
    CLUSTER_NAME="bcm-$(hostname)"
fi

if [[ $BCM_CLI_VERB == "create" ]]; then
    if bcm cluster list | grep -q "$CLUSTER_NAME"; then
        echo "The BCM Cluster '$CLUSTER_NAME' already exists!"
        exit
    fi
    
    CLUSTER_DIR="$BCM_WORKING_DIR/$CLUSTER_NAME"
    ENDPOINT_DIR="$CLUSTER_DIR/$BCM_SSH_HOSTNAME-01"
    mkdir -p "$ENDPOINT_DIR"
    
    # first check to ensure that the cluster doesn't already exist.
    if ! lxc remote list | grep -q "$CLUSTER_NAME"; then
        bash -c "$BCM_GIT_DIR/cluster/up_cluster_master.sh --driver=$BCM_DRIVER --cluster-name=$CLUSTER_NAME --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME --endpoint-dir=$ENDPOINT_DIR"
    else
        echo "ERROR: BCM cluster 'CLUSTER_NAME' already exists!"
        exit
    fi
fi

if [[ $BCM_CLI_VERB == "destroy" ]]; then
    if [[ $(lxc remote get-default) == "local" ]]; then
        echo "ERROR: The current LXD remote is set to 'local'. You may not have a cluster to destroy."
        exit
    fi
    
    CONTINUE=0
    while [[ "$CONTINUE" == 0 ]]
    do
        echo "WARNING: Are you sure you want to delete the current cluster '$(lxc remote get-default)'? This will DESTROY ALL DATA!!!"
        read -rp "Are you sure (y/n):  "   CHOICE
        
        if [[ "$CHOICE" == "y" ]]; then
            CONTINUE=1
            elif [[ "$CHOICE" == "n" ]]; then
            exit
        else
            echo "Invalid entry. Please try again."
        fi
    done
    
    
    if [[ $BCM_DRIVER == multipass ]]; then
        BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"
        if multipass list | grep -q "$BCM_SSH_HOSTNAME"; then
            multipass stop "$BCM_SSH_HOSTNAME"
            multipass delete "$BCM_SSH_HOSTNAME"
            multipass purge
        fi
        
        # remove the entry for the host in your BCM_KNOWN_HOSTS_FILE
        ssh-keygen -f "$BCM_KNOWN_HOSTS_FILE" -R "$BCM_SSH_HOSTNAME" >> /dev/null
    fi
    
    CLUSTER_DIR="$BCM_WORKING_DIR/$CLUSTER_NAME"
    ENDPOINT_DIR="$CLUSTER_DIR/$BCM_SSH_HOSTNAME"
    bash -c "$BCM_GIT_DIR/cluster/destroy_cluster_master.sh --endpoint-dir=$ENDPOINT_DIR --cluster-name=$CLUSTER_NAME --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME"
    
    # update the SDN Controller's /etc/hosts file if it's a multipass VM.
    if [[ $BCM_DRIVER == multipass ]]; then
        bash -c "$BCM_GIT_DIR/cli/shared/update_controller_etc_hosts.sh"
    fi
fi
