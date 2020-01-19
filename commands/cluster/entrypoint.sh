#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

ALL_FLAG=0

for i in "$@"; do
    case $i in
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

# bcm cluster create provisions a new BCM cluster to the localhost
if [[ $BCM_CLI_VERB == "create" ]]; then
    bash -c "$BCM_GIT_DIR/commands/cluster/cluster_create.sh"
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
            # TODO ensure we're using an encrypted storage backend for all $BCM_TMP_DIR files
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
