#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a SSH command."
    cat ./help.txt
    exit
fi

BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=
BCM_SSH_PUSH=0
BCM_CLUSTER_NAME=
BCM_ENDPOINT_NAME=

for i in "$@"; do
    case $i in
        --endpoint-name=*)
            BCM_ENDPOINT_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --push)
            BCM_SSH_PUSH=1
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# if the cluster name wasn't passed, we assume the user@hostname is a member to the active LXD cluster.
if [[ -z $BCM_CLUSTER_NAME ]]; then
    BCM_CLUSTER_NAME=$(lxc remote get-default)
    
    if [[ $BCM_CLUSTER_NAME == "local" ]]; then
        echo "ERROR: LXC remote is set to local. ALL BCM activities are performed over HTTPS (even for local/standalone installs). Perhaps you need to run 'bcm cluster create'?"
        exit
    fi
fi

export TEMP_DIR="$BCM_TEMP_DIR/$BCM_CLUSTER_NAME/$BCM_ENDPOINT_NAME"
mkdir -p "$TEMP_DIR/ssh"
if [[ ! -d "$TEMP_DIR/ssh" ]]; then
    echo "ERROR: '$TEMP_DIR' doesn't exist."
    exit
fi

if [[ ! -f "$TEMP_DIR/env" ]]; then
    echo "ERROR: '$TEMP_DIR/env' doesn't exist."
    exit
fi

# shellcheck disable=SC1090
source "$TEMP_DIR/env"

if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "Error:  BCM_SSH_USERNAME not set."
fi

if [[ -z "$BCM_SSH_HOSTNAME" ]]; then
    echo "Error:  BCM_SSH_HOSTNAME not set."
fi

# shellcheck disable=1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"
if [[ ! -z "$BCM_TREZOR_USB_PATH" ]]; then
    if [[ $BCM_CLI_VERB == "newkey" ]]; then
        if [[ -z $BCM_ENDPOINT_NAME ]]; then
            echo "BCM_ENDPOINT_NAME is empty."
            cat ./newkey/help.txt
            exit
        fi
        
        KEY_NAME="$BCM_SSH_USERNAME""_""$BCM_SSH_HOSTNAME.pub"
        PUB_KEY_PATH="$SSH_DIR/$KEY_NAME"
        mkdir -p "$SSH_DIR"
        
        sudo docker run -t --rm \
        -v "$SSH_DIR":/root/.ssh \
        -e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
        -e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME > /root/.ssh/$BCM_SSH_USERNAME""_""$BCM_SSH_HOSTNAME.pub"
        
        if [[ -f "$PUB_KEY_PATH" ]]; then
            echo "Congratulations! Your new SSH public key can be found at '$PUB_KEY_PATH'"
            
            # Push to desintion if specified.
            if [[ $BCM_SSH_PUSH == 1 ]]; then
                if [[ $BCM_SSH_HOSTNAME == *.onion ]]; then
                    torify ssh-copy-id -f -i "$PUB_KEY_PATH" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
                else
                    ssh-copy-id -f -i "$PUB_KEY_PATH" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
                fi
            fi
            
            # save the pubkey in our password store.
            bcm file encrypt --input-file-path="$PUB_KEY_PATH" --output-dir="$SSH_DIR"
        else
            echo "ERROR: SSH Key did not generate successfully!"
        fi
        
        elif [[ $BCM_CLI_VERB == "connect" ]]; then
        
        if [[ ! -f "$TEMP_DIR/env" ]]; then
            echo "ERROR: $TEMP_DIR/env does not exist."
            exit
        fi
                
        # shellcheck disable=SC1090
        source "$TEMP_DIR/env"
        
        if [[ -z $BCM_SSH_HOSTNAME ]]; then
            echo "BCM_SSH_HOSTNAME is empty."
            cat ./newkey/help.txt
            exit
        fi
        
        if [[ -z $BCM_SSH_USERNAME ]]; then
            echo "BCM_SSH_USERNAME is empty."
            cat ./newkey/help.txt
            exit
        fi
        
        sudo docker run -it --rm --add-host="$BCM_SSH_HOSTNAME:$(dig +short "$BCM_SSH_HOSTNAME")" \
        -v "$TEMP_DIR":/root/.ssh \
        -e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
        -e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME --connect --verbose"
        elif [[ $BCM_CLI_VERB == "list" ]]; then
        bcm pass list | grep 'bcm/ssh/'
    else
        cat ./help.txt
    fi
fi