#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a ssh command."
    cat ./help.txt
    exit
fi

SSH_USERNAME=
SSH_HOSTNAME=
SSH_PUSH=0
SSH_KEY_PATH=
ENDPOINT_DIR=
ONION_ADDRESS=
AUTH_TOKEN=
TITLE=

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
        --onion=*)
            ONION_ADDRESS="${i#*=}"
            shift # past argument=value
        ;;
        --token=*)
            AUTH_TOKEN="${i#*=}"
            shift # past argument=value
        ;;
        --title=*)
            TITLE="${i#*=}"
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

if [[ ! -d "$BCM_SSH_DIR" ]]; then
    mkdir "$BCM_SSH_DIR"
fi

if [[ ! -f "$BCM_KNOWN_HOSTS_FILE" ]]; then
    touch "$BCM_KNOWN_HOSTS_FILE"
fi


if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ $BCM_CLI_VERB == "newkey" ]]; then
    
    
    # shellcheck disable=SC1090
    source "$BCM_GIT_DIR/controller/export_usb_path.sh"
    if [[ -z "$BCM_TREZOR_USB_PATH" ]]; then
        echo "Could not determine Trezor USB PATH."
        exit
    fi
    
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./newkey/help.txt
        exit
    fi
    
    KEY_NAME="id_rsa_trezor.pub"
    TREZOR_PUB_KEY_PATH="$ENDPOINT_DIR/$KEY_NAME"
    
    docker run -t --rm \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$ENDPOINT_DIR":/home/user/.ssh \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    -e KEY_NAME="$KEY_NAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME > /home/user/.ssh/$KEY_NAME"
    
    if [[ ! -f "$TREZOR_PUB_KEY_PATH" ]]; then
        echo "Error: SSH Key did not generate successfully!"
        exit
    fi
    
    #echo "Congratulations! Your new SSH public key can be found at '$TREZOR_PUB_KEY_PATH'"
    
    # We'll stop here unless instructed to push the new key.
    if [[ $SSH_PUSH != 1 ]]; then
        exit
    fi
    
    if [[ -f $SSH_KEY_PATH ]]; then
        # push the trezor ssh pubkey to the destination.
        ssh-copy-id -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$SSH_USERNAME@$SSH_HOSTNAME"
        
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
    # shellcheck disable=SC1090
    source "$BCM_GIT_DIR/controller/export_usb_path.sh"
    if [[ -z "$BCM_TREZOR_USB_PATH" ]]; then
        echo "Could not determine Trezor USB PATH."
        exit
    fi
    
    IP_ADDRESS=$(dig +short "$SSH_HOSTNAME" | head -n 1)
    docker run -it --rm --add-host="$SSH_HOSTNAME:$IP_ADDRESS" \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" bash -c "trezor-agent $SSH_USERNAME@$SSH_HOSTNAME --connect --verbose"
    
    exit
fi


if [[ $BCM_CLI_VERB == "add-onion" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./addonion/help.txt
        exit
    fi
    
    if [[ -z $ONION_ADDRESS ]]; then
        echo "Error: ONION_ADDRESS is not defined. Use --onion=<ONION_ADDRESS>"
        exit
    fi
    
    if [[ -z $AUTH_TOKEN ]]; then
        echo "Error: AUTH_TOKEN is not defined. Use --token=<AUTH_TOKEN>"
        exit
    fi
    
    if [[ -z $TITLE ]]; then
        echo "Error: TITLE is not defined. Use --title=<TITLE>"
        exit
    fi
    
    # construct the tor string.
    TOR_STRING="HidServAuth $ONION_ADDRESS $AUTH_TOKEN #BCM_SSH: $TITLE"
    TORRC=/etc/tor/torrc
    if grep -Fxq "$TOR_STRING" "$TORRC"; then
        echo "This SSH endpoint '$TITLE' is already defined in '$TORRC'. You can use 'bcm ssh remove-onion' to remove it.'"
    else
        # let's further check to ensure you're not inserting an existing onion address else the tor service
        # won't start due to duplicates.
        if ! grep -Fxq "$ONION_ADDRESS" "$TORRC"; then
            echo "$TOR_STRING" | sudo tee -a "$TORRC" >>/dev/null
            sudo systemctl reload tor
            wait-for-it -t 15 --quiet 127.0.0.1:9050>>/dev/null
            
            echo "$TITLE has been added to $TORRC and your local tor client has been reloaded."
        else
            echo "WARNING: you already have an onion endpoint with the same onion address! No changes were made."
        fi
    fi
    
    exit
fi


if [[ $BCM_CLI_VERB == "remove-onion" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./removeonion/help.txt
        exit
    fi
    
    if [[ -z $TITLE ]]; then
        echo "Error: TITLE is not defined. Use --title=<TITLE>"
        exit
    fi
    
    # construct the tor string.
    TORRC=/etc/tor/torrc
    if grep -q "#BCM_SSH: $TITLE" "$TORRC"; then
        sudo sed -i '/'"#BCM_SSH: $TITLE"'/d' "$TORRC"
        
        # restart tor daemon
        # TODO only restart if the line was in there in the first place
        sudo systemctl reload tor >>/dev/null
        wait-for-it -t 15 --quiet 127.0.0.1:9050>>/dev/null
        
        echo "'$TITLE' has been removed from '$TORRC' and your local tor daemon has been reloaded."
    else
        echo "'$TITLE' was not found in $TORRC"
    fi
    
    exit
fi

if [[ $BCM_CLI_VERB == "list-onion" ]]; then
    echo "TITLE,ONION_ADDRESS"
    while read -r LINE; do
        if [[ "$LINE" =~ "#BCM_SSH:" ]]; then
            TITLE=$(echo "$LINE" | awk '{print $5;}')
            ONION=$(echo "$LINE"| awk '{print $2;}')
            echo "$TITLE,$ONION"
        fi
    done </etc/tor/torrc
fi


if [[ $BCM_CLI_VERB == "push-key" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./push/help.txt
        exit
    fi
    
    # shellcheck disable=SC1090
    source "$BCM_GIT_DIR/controller/export_usb_path.sh"
    
    IP_ADDRESS=$(dig +short "$SSH_HOSTNAME" | head -n 1)
    docker run -it --rm --add-host="$SSH_HOSTNAME:$IP_ADDRESS" \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$BCM_SSH_DIR":/home/user/.ssh \
    -v "$GIT_REPO_DIR":/gitrepo \
    -e GIT_CLIENT_USERNAME="$GIT_CLIENT_USERNAME" \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    "bcm-trezor:$BCM_VERSION" trezor-agent $SSH_USERNAME@$SSH_HOSTNAME -- service tor start && wait-for-it -t 10 127.0.0.1:9050 && git config --local http.proxy socks5://127.0.0.1:9050 && git config --local user.name "$GIT_CLIENT_USERNAME" && git push
fi
