#!/bin/bash

set -Eeuox pipefail
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
fi

export TEMP_DIR="$BCM_TEMP_DIR/$BCM_CLUSTER_NAME/$BCM_ENDPOINT_NAME"
if [[ ! -d "$TEMP_DIR" ]]; then
    echo "ERROR: '$TEMP_DIR' doesn't exist."
    exit
fi

if [[ ! -f "$TEMP_DIR/env" ]]; then
    echo "ERROR: '$TEMP_DIR/env' doesn't exist."
    exit
fi

source "$TEMP_DIR/env"

if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "Error:  BCM_SSH_USERNAME not set."
fi

if [[ -z "$BCM_SSH_HOSTNAME" ]]; then
    echo "Error:  BCM_SSH_HOSTNAME not set."
fi

# shellcheck disable=1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"

export BCM_SSH_USERNAME="$BCM_SSH_USERNAME"
export BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"

if [[ ! -z "$BCM_TREZOR_USB_PATH" ]]; then
    
    if [[ $BCM_CLI_VERB == "newkey" ]]; then
        
        
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
        
        # if they're both empty, let's check to see if they used the 'user@hostname' format instead.
        if [[ -z $BCM_SSH_USERNAME && -z $BCM_SSH_HOSTNAME ]]; then
            USER_HOSTNAME=${3:-}
            if [ ! -z "${USER_HOSTNAME}" ]; then
                BCM_SSH_USERNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f1)
                BCM_SSH_HOSTNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f2)
            else
                echo "Provide the username & hostname:  user@host"
                cat ./help.txt
                exit
            fi
        fi
        
        KEY_NAME="$BCM_SSH_USERNAME""_""$BCM_SSH_HOSTNAME.pub"
        PUB_KEY_PATH="$TEMP_DIR/$KEY_NAME"
        
        sudo docker run -it --rm \
        -v "$TEMP_DIR":/root/.ssh \
        -e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
        -e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
        -e KEY_NAME="$KEY_NAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest bash -c "trezor-agent -vv $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME > /root/.ssh/$KEY_NAME && sleep 60"
        # PUB_KEY=$(sudo docker run -it --rm \
        #     -v "$TEMP_DIR":/root/.ssh \
        #     -e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
        #     -e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
        #     -e KEY_NAME="$KEY_NAME" \
        #     --device="$BCM_TREZOR_USB_PATH" \
        # bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME")
        # echo "$PUB_KEY" >> "$TEMP_DIR/temp.pub"
        # grep "ecdsa-sha2-nistp256" "$TEMP_DIR/temp.pub" >> "$PUB_KEY_PATH"
        # rm "$TEMP_DIR/temp.pub"
        
        
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
        else
            echo "ERROR: SSH Key did not generate successfully!"
        fi
        
        elif [[ $BCM_CLI_VERB == "connect" ]]; then
        
        if [[ ! -f "$TEMP_DIR/env" ]]; then
            echo "ERROR: $TEMP_DIR/env does not exist."
            exit
        fi
        
        
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