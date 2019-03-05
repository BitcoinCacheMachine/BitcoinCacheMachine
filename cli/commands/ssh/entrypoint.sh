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
BCM_SSH_KEY_PATH=

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
        --ssh-key-path=*)
            BCM_SSH_KEY_PATH="${i#*=}"
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
    PUB_KEY_PATH="$BCM_SSH_DIR/$KEY_NAME"
    mkdir -p "$BCM_SSH_DIR"
    
    sudo docker run -t --rm \
    -v "$BCM_SSH_DIR":/root/.ssh \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME > /root/.ssh/$SSH_USERNAME""_""$SSH_HOSTNAME.pub"
    
    if [[ -f "$PUB_KEY_PATH" ]]; then
        echo "Congratulations! Your new SSH public key can be found at '$PUB_KEY_PATH'"
        
        # Push to desintion if specified.
        if [[ $SSH_PUSH == 1 ]]; then
            if [[ $SSH_HOSTNAME == *.onion ]]; then
                echo "TODO"
                #torify ssh-copy-id -f -i "$PUB_KEY_PATH" "$SSH_USERNAME@$SSH_HOSTNAME"
            else
                # we assume here that we have an SSH connection to push an AUTHORIZED_KEYS entry.
                if [[ ! -z $BCM_SSH_KEY_PATH ]]; then
                    if [[ -f $BCM_SSH_KEY_PATH ]]; then
                        ssh -i "$BCM_SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$SSH_USERNAME@$SSH_HOSTNAME" sudo tee -a /home/bcm/.ssh/authorized_keys < "$PUB_KEY_PATH"
                        
                        # # #REMOVE ALL OTHER KEYS EXCEPT THE NEW ONE
                        # # # we're going to remove the SSH PUBKEY from BCM_SSH_KEY_PATH from the authorized_keys
                        # # # file on the remote host. Then we're going to delete
                        # cat "$PUB_KEY_PATH" | ssh -i "$BCM_SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$SSH_USERNAME@$SSH_HOSTNAME" 'cat > /home/bcm/.ssh/authorized_keys'
                        
                        # rm -f "BCM_SSH_KEY_PATH"
                        # rm -f "$BCM_SSH_KEY_PATH.pub"
                        
                        # remove the entry for the host in your BCM_KNOWN_HOSTS_FILE
                        ssh-keygen -f "$BCM_KNOWN_HOSTS_FILE" -R "$SSH_HOSTNAME"  >> /dev/null
                        
                        # new key is up there, now let's do a ssh-keyscan from our SDN controller
                        # so we won't get any annoying warnings about keys changing.
                        ssh-keyscan -H "$SSH_HOSTNAME" >> "$BCM_KNOWN_HOSTS_FILE"
                        
                        exit
                    fi
                fi
            fi
        fi
        
        # save the pubkey in our password store.
        #bcm file encrypt --input-file-path="$PUB_KEY_PATH" --output-dir="$BCM_SSH_DIR"
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
    -v "$BCM_SSH_DIR":/root/.ssh \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME --connect --verbose"
fi


if [[ $BCM_CLI_VERB == "list" ]]; then
    bcm pass list | grep 'bcm/ssh/'
fi
