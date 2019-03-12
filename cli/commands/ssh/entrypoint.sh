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
SSH_KEY_PATH=
ENDPOINT_DIR=

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
        --endpoint-dir=*)
            ENDPOINT_DIR="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-key-path=*)
            SSH_KEY_PATH="${i#*=}"
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
    
    KEY_NAME="id_rsa_trezor.pub"
    TREZOR_PUB_KEY_PATH="$ENDPOINT_DIR/$KEY_NAME"
    
    docker run -t --rm \
    -v "$ENDPOINT_DIR":/root/.ssh \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    -e KEY_NAME="$KEY_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME > /root/.ssh/$KEY_NAME"
    
    if [[ ! -f "$TREZOR_PUB_KEY_PATH" ]]; then
        echo "ERROR: SSH Key did not generate successfully!"
        exit
    fi
    
    #echo "Congratulations! Your new SSH public key can be found at '$TREZOR_PUB_KEY_PATH'"
    
    # We'll stop here unless instructed to push the new key.
    if [[ $SSH_PUSH != 1 ]]; then
        exit
    fi
    
    if [[ -f $SSH_KEY_PATH ]]; then
        # push the trezor ssh pubkey to the destination.
        ssh -t -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$SSH_USERNAME@$SSH_HOSTNAME" sudo tee -a "/home/$SSH_USERNAME/.ssh/authorized_keys" < "$TREZOR_PUB_KEY_PATH"
        
        # remove the entry for the host in your BCM_KNOWN_HOSTS_FILE
        ssh-keygen -f "$BCM_KNOWN_HOSTS_FILE" -R "$SSH_HOSTNAME"  >> /dev/null
        
        # new key is up there, now let's do a ssh-keyscan from our SDN controller
        # so we won't get any annoying warnings about keys changing.
        ssh-keyscan -H "$SSH_HOSTNAME" >> "$BCM_KNOWN_HOSTS_FILE"
        
        exit
    fi
fi

if [[ $BCM_CLI_VERB == "connect" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./connect/help.txt
        exit
    fi
    
    IP_ADDRESS=$(dig +short "$SSH_HOSTNAME" | head -n 1)
    docker run -it --rm --add-host="$SSH_HOSTNAME:$IP_ADDRESS" \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME --connect --verbose"
    
    exit
fi


if [[ $BCM_CLI_VERB == "list" ]]; then
    bcm pass list | grep 'bcm/ssh/'
fi
