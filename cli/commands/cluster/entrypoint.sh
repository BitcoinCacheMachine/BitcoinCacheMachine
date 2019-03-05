#!/bin/bash

set -Eeuo pipefail
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

# Check to see if the computer has hardware virtualization support. If not, then we
# switch our driver to SSH.
if ! lscpu | grep "Virtualization:" | cut -d ":" -f 2 | xargs | grep -q "VT-x"; then
    echo "Your computer does NOT support hardware virtualization. You may need to turn this feature on in the BIOS. BCM will be deployed to your machine in a baremetal configuration."
    BCM_DRIVER=ssh
fi

if [[ $BCM_DRIVER != "ssh" && $BCM_DRIVER != "multipass" ]]; then
    echo "ERROR: BCM Cluster driver MUST be 'ssh' or 'multipass'."
    exit
fi

if [[ $BCM_DRIVER == "multipass" ]]; then
    bash -c "$BCM_GIT_DIR/cli/commands/install/snap_multipass_install.sh"
fi

if [[ "$BCM_CLI_VERB" == "list" ]]; then
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        lxc cluster list | grep "$BCM_CLUSTER_NAME" | awk '{print $2}'
        exit
    fi
    
    lxc remote list --format csv | grep "$BCM_CLUSTER_NAME" | awk -F "," '{print $1}' | awk '{print $1}'
    
    exit
fi

# if the cluster name is local, then we assume the user hasn't overridden
# what was set in 'lxc remote get-default'. If so, we will assume a cluster
# will be created with the name of `hostname`
if [[ $BCM_CLUSTER_NAME == "local" ]]; then
    BCM_CLUSTER_NAME="$(hostname)"
fi

if [[ -z $BCM_SSH_USERNAME ]]; then
    BCM_SSH_USERNAME=bcm
fi

# strip the PREFIX and get just the SSH_HOSTNAME.
BCM_SSH_HOSTNAME=${BCM_CLUSTER_NAME#"$PREFIX"}

if [[ $BCM_CLI_VERB == "create" ]]; then
    if bcm cluster list | grep -q "$BCM_CLUSTER_NAME"; then
        echo "The BCM Cluster '$BCM_CLUSTER_NAME' already exists!"
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
    if [[ $BCM_DRIVER == multipass ]]; then
        VM_NAME="$BCM_CLUSTER_NAME"
        if multipass list | grep -q "$VM_NAME"; then
            multipass stop "$VM_NAME"
            multipass delete "$VM_NAME"
            multipass delete "$VM_NAME"
        fi
        
        multipass purge
        
        # remove the entry for the host in your BCM_KNOWN_HOSTS_FILE
        ssh-keygen -f "$BCM_KNOWN_HOSTS_FILE" -R "$VM_NAME" >> /dev/null
    fi
    
    export BCM_CLUSTER_NAME="$BCM_CLUSTER_NAME"
    bash -c "$BCM_GIT_DIR/cluster/destroy_cluster_master.sh --cluster-name=$BCM_CLUSTER_NAME  --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME"
    
    # update the SDN controller's /etc/hosts file if it's a multipass VM.
    if [[ $BCM_DRIVER == multipass ]]; then
        bash -c "$BCM_GIT_DIR/cli/shared/update_controller_etc_hosts.sh"
    fi
fi
