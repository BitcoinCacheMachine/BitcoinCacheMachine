#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

BCM_ENDPOINTS_FLAG=0
ALL_FLAG=0

for i in "$@"; do
    case $i in
        endpoints)
            BCM_ENDPOINTS_FLAG=1
            shift # past argument=value
        ;;
        --create)
            BCM_CLI_VERB="create"
        ;;
        --all)
            ALL_FLAG=1
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
        lxc cluster list --format csv | grep "$BCM_SSH_HOSTNAME" | awk -F"," '{print $1}'
        exit
    fi
    
    lxc remote list --format csv | grep "bcm-" | awk -F "," '{print $1}' | awk -F"," '{print $1}'
    exit
fi

# bcm cluster create provisions a new BCM cluster to the localhost
if [[ $BCM_CLI_VERB == "create" ]]; then
    # since we're doing a local install; we can just connect our wirepoint
    # endpoint listening service on the same interface being used for our
    # default route. TODO; add CLI option to specify address.
    MACVLAN_INTERFACE="$(ip route | grep default | cut -d " " -f 5)"
    IP_OF_MACVLAN_INTERFACE="$(ip addr show "$MACVLAN_INTERFACE" | grep "inet " | cut -d/ -f1 | awk '{print $NF}')"
    BCM_LXD_SECRET="$(apg -n 1 -m 30 -M CN)"
    export BCM_LXD_SECRET="$BCM_LXD_SECRET"
    export MACVLAN_INTERFACE="$MACVLAN_INTERFACE"
    LXD_SERVER_NAME="$BCM_SSH_HOSTNAME"
    # these two lines are so that ssh hosts can have the correct naming convention for LXD node info.
    if [[ ! "$LXD_SERVER_NAME" == *"-01"* ]]; then
        LXD_SERVER_NAME="$LXD_SERVER_NAME-01"
    fi
    
    if [[ ! "$LXD_SERVER_NAME" == *"bcm-"* ]]; then
        LXD_SERVER_NAME="bcm-$LXD_SERVER_NAME"
    fi
    
    export LXD_SERVER_NAME="$LXD_SERVER_NAME"
    export IP_OF_MACVLAN_INTERFACE="$IP_OF_MACVLAN_INTERFACE"
    PRESEED_YAML="$(envsubst <./lxd_preseed/lxd_master_preseed.yml)"
    sudo bash -c "$BCM_GIT_DIR/commands/install/endpoint_provision.sh --yaml-text='$PRESEED_YAML'"
    exit
fi

# this is where we implement 'bcm cluster destroy'
if [[ $BCM_CLI_VERB == "clear" ]]; then
    # TODO convert this to git and reference the upstream repo script. https://github.com/lxc/lxd/blob/master/scripts/empty-lxd.sh
    CONTINUE=0
    while [[ "$CONTINUE" == 0 ]]; do
        echo "WARNING: Are you sure you want to delete all LXD objects from cluster '$BCM_SSH_HOSTNAME'? This will DESTROY ALL DATA!!!"
        read -rp "Are you sure (y/n):  " CHOICE
        
        if [[ "$CHOICE" == "y" ]]; then
            CONTINUE=1
            # let's ensure our remote git repo is updated.
            # TODO move this over a TOR connection via PROXY switch/config.
            # TODO ensure we're using an encrypted storage backend for all /tmp/bcm files
            # by default we retain images to make development easier.
            bash -c "./clear_lxd.sh --delete-images=$ALL_FLAG"
            
            elif [[ "$CHOICE" == "n" ]]; then
            echo "INFO:  Aborted 'bcm cluster clear' command."
            exit
        else
            echo "Invalid entry. Please try again."
        fi
    done
fi


# this is where we implement 'bcm cluster destroy'
if [[ $BCM_CLI_VERB == "destroy" ]]; then
    
    echo "INFO: Calling 'bcm cluster clear'. Images will be deleted."
    bash -c ./clear_lxd.sh --retain-images=0 >>/dev/null
    
    echo "INFO: Removing the LXD snap."
    sudo snap remove lxd
fi
