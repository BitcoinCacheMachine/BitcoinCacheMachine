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

SSH_USERNAME=
SSH_HOSTNAME=
SSH_PUSH=0

for i in "$@"; do
    case $i in
        --hostname=*)
            SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --username=*)
            SSH_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --push)
            SSH_PUSH=1
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $SSH_HOSTNAME ]]; then
    echo "SSH_HOSTNAME can't be empty."
fi

if [[ -z $SSH_USERNAME ]]; then
    echo "Error:  SSH_USERNAME not set"
    exit
fi

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"
if [[ -z "$BCM_TREZOR_USB_PATH" ]]; then
    echo "Could not determine Trezor USB PATH."
    exit
fi

if [[ $BCM_CLI_VERB == "newkey" ]]; then
    if [[ -z $SSH_HOSTNAME ]]; then
        echo "SSH_HOSTNAME is empty."
        cat ./newkey/help.txt
        exit
    fi
    
    KEY_NAME="$SSH_USERNAME""_""$SSH_HOSTNAME.pub"
    PUB_KEY_PATH="$SSH_DIR/$KEY_NAME"
    mkdir -p "$SSH_DIR"
    
    sudo docker run -t --rm \
    -v "$SSH_DIR":/root/.ssh \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME > /root/.ssh/$SSH_USERNAME""_""$SSH_HOSTNAME.pub"
    
    if [[ -f "$PUB_KEY_PATH" ]]; then
        echo "Congratulations! Your new SSH public key can be found at '$PUB_KEY_PATH'"
        
        # Push to desintion if specified.
        if [[ $SSH_PUSH == 1 ]]; then
            if [[ $SSH_HOSTNAME == *.onion ]]; then
                torify ssh-copy-id -f -i "$PUB_KEY_PATH" "$SSH_USERNAME@$SSH_HOSTNAME"
            else
                ssh-copy-id -f -i "$PUB_KEY_PATH" "$SSH_USERNAME@$SSH_HOSTNAME"
            fi
        fi
        
        # save the pubkey in our password store.
        #bcm file encrypt --input-file-path="$PUB_KEY_PATH" --output-dir="$SSH_DIR"
    else
        echo "ERROR: SSH Key did not generate successfully!"
    fi
fi


if [[ $BCM_CLI_VERB == "connect" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./connect/help.txt
        exit
    fi
    
    
    IP_ADDRESS=$(dig +short "$SSH_HOSTNAME" | head -n 1)
    sudo docker run -it --rm --add-host="$SSH_HOSTNAME:$IP_ADDRESS" \
    -v "$SSH_DIR":/root/.ssh \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME --connect --verbose"
fi


if [[ $BCM_CLI_VERB == "list" ]]; then
    bcm pass list | grep 'bcm/ssh/'
fi